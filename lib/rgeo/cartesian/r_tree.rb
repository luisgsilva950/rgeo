# frozen_string_literal: true

module RGeo
  module Cartesian
    # A dynamic, two-dimensional R-tree for Cartesian geometries. Inserts may
    # be interleaved with queries; neither operation builds or seals the tree.
    #
    # Queries return items whose stored XY bounding boxes intersect the query's
    # bounding box, including boundary contact. These are candidates, not exact
    # geometry intersections. Z and M coordinates are ignored. Bounding boxes
    # are captured on insertion, so geometries need not be retained. Items are
    # retained by identity, and repeated insertions remain separate entries.
    #
    # All geometries must belong to the exact factory object supplied when the
    # tree is created. No factory conversion or coordinate transformation occurs.
    # Instances cannot be duplicated or cloned. Freezing prevents insertion but
    # still permits queries. Concurrent mutation requires external synchronization.
    class RTree
      # Returns the number of inserted entries, including duplicates.
      attr_reader :size

      # Creates an empty tree for a factory guaranteeing Cartesian coordinates.
      # +max_entries+ is the maximum number of entries per node (default 16).
      # It must be an Integer of at least 4. Non-root nodes contain at least
      # +max_entries / 2+ entries, and all leaves have the same depth.
      #
      # Raises ArgumentError for an invalid factory or node capacity.
      def initialize(factory, max_entries: 16)
        unless factory.is_a?(Feature::Factory::Instance) && factory.property(:is_cartesian) == true
          raise ArgumentError, "factory must guarantee Cartesian coordinates"
        end
        unless max_entries.is_a?(Integer) && max_entries >= 4
          raise ArgumentError, "max_entries must be an Integer of at least 4"
        end

        @factory = factory
        @max_entries = max_entries
        @min_entries = max_entries / 2
        @root = Node.new(true)
        @size = 0
      end

      # Inserts +item+ with a snapshot of +geometry+'s XY bounding box and
      # returns self. Any Ruby object, including nil, may be stored as an item.
      #
      # Raises ArgumentError for an empty geometry, a geometry from another
      # factory, a non-geometry, or non-finite XY bounds. Raises FrozenError
      # if the tree is frozen. A rejected insertion leaves the tree unchanged.
      def insert(geometry, item)
        raise FrozenError, "can't modify frozen #{self.class}" if frozen?

        bounds = geometry_bounds(geometry)
        raise ArgumentError, "cannot insert an empty geometry" unless bounds

        sibling = insert_entry(@root, Entry.new(bounds, item))
        if sibling
          root = Node.new(false)
          root.add(@root)
          root.add(sibling)
          @root = root
        end
        @size += 1
        self
      end

      # Returns an unordered Array of items whose stored bounding boxes
      # intersect +geometry+'s XY bounding box. An empty query returns [].
      # Duplicate entries yield duplicate items; item identity is preserved.
      # Queries do not change the tree or prevent subsequent insertions.
      #
      # Raises ArgumentError for a non-geometry, a geometry from another
      # factory, or non-finite XY bounds.
      def query(geometry)
        bounds = geometry_bounds(geometry)
        results = []
        return results unless bounds && @root.bounds&.intersects?(bounds)

        pending = [@root]
        until pending.empty?
          node = pending.pop
          node.entries.each do |entry|
            next unless entry.bounds.intersects?(bounds)

            if node.leaf
              results << entry.item
            else
              pending << entry
            end
          end
        end
        results
      end

      private

      # Mutable bounds belong only to nodes; leaf-entry bounds never change.
      class Bounds # :nodoc:
        attr_reader :min_x, :min_y, :max_x, :max_y

        def initialize(min_x, min_y, max_x, max_y)
          @min_x = min_x
          @min_y = min_y
          @max_x = max_x
          @max_y = max_y
        end

        def expand(other)
          @min_x = other.min_x if other.min_x < @min_x
          @min_y = other.min_y if other.min_y < @min_y
          @max_x = other.max_x if other.max_x > @max_x
          @max_y = other.max_y if other.max_y > @max_y
        end

        def area
          (@max_x - @min_x) * (@max_y - @min_y)
        end

        def union_area(other)
          min_x = other.min_x < @min_x ? other.min_x : @min_x
          min_y = other.min_y < @min_y ? other.min_y : @min_y
          max_x = other.max_x > @max_x ? other.max_x : @max_x
          max_y = other.max_y > @max_y ? other.max_y : @max_y
          (max_x - min_x) * (max_y - min_y)
        end

        def intersects?(other)
          @min_x <= other.max_x && @max_x >= other.min_x &&
            @min_y <= other.max_y && @max_y >= other.min_y
        end
      end

      class Node # :nodoc:
        attr_reader :leaf, :entries, :bounds

        def initialize(leaf)
          @leaf = leaf
          @entries = []
          @bounds = nil
        end

        def add(entry)
          @entries << entry
          if @bounds
            @bounds.expand(entry.bounds)
          else
            @bounds = entry.bounds.dup
          end
        end

        def reset
          @entries = []
          @bounds = nil
        end
      end

      Entry = Struct.new(:bounds, :item)
      private_constant :Bounds, :Node, :Entry

      def initialize_copy(_other)
        raise TypeError, "#{self.class} cannot be copied"
      end

      def geometry_bounds(geometry)
        unless Feature::Geometry === geometry && geometry.factory.equal?(@factory)
          raise ArgumentError, "geometry must belong to this tree's factory"
        end
        return if geometry.empty?

        # Native envelopes avoid materializing every vertex in Ruby. The simple
        # factory already computes envelopes with BoundingBox, so use it directly.
        source = @factory.is_a?(Factory) ? geometry : geometry.envelope
        box = BoundingBox.new(@factory, ignore_z: true, ignore_m: true).add_geometry(source)
        coordinates = [box.min_x, box.min_y, box.max_x, box.max_y]
        unless coordinates.all? { |coordinate| coordinate&.finite? }
          raise ArgumentError, "geometry must have finite XY bounds"
        end

        Bounds.new(*coordinates)
      end

      # Recursive insertion returns the new sibling when a node splits. Only
      # splitting the root increases the height, keeping every leaf balanced.
      def insert_entry(node, entry)
        if node.leaf
          node.add(entry)
        else
          sibling = insert_entry(choose_subtree(node, entry.bounds), entry)
          node.bounds.expand(entry.bounds)
          node.add(sibling) if sibling
        end
        split(node) if node.entries.size > @max_entries
      end

      def choose_subtree(node, bounds)
        best = nil
        best_growth = best_area = best_count = nil
        node.entries.each do |child|
          area = child.bounds.area
          growth = child.bounds.union_area(bounds) - area
          count = child.entries.size
          next unless !best || growth < best_growth ||
             (growth == best_growth && (area < best_area || (area == best_area && count < best_count)))
          best = child
          best_growth = growth
          best_area = area
          best_count = count
        end
        best
      end

      # Guttman's quadratic split: choose the pair wasting the most bounding
      # area, then assign the entry with the strongest enlargement preference.
      # Force remaining entries into a group when needed for minimum occupancy.
      def split(node)
        remaining = node.entries
        first, second = split_seeds(remaining)
        right_seed = remaining.delete_at(second)
        left_seed = remaining.delete_at(first)
        node.reset
        sibling = Node.new(node.leaf)
        node.add(left_seed)
        sibling.add(right_seed)

        until remaining.empty?
          if node.entries.size + remaining.size == @min_entries
            remaining.each { |entry| node.add(entry) }
            break
          elsif sibling.entries.size + remaining.size == @min_entries
            remaining.each { |entry| sibling.add(entry) }
            break
          end

          index, left_growth, right_growth = split_next(remaining, node.bounds, sibling.bounds)
          entry = remaining.delete_at(index)
          left_area = node.bounds.area
          right_area = sibling.bounds.area
          if left_growth < right_growth ||
             (left_growth == right_growth &&
              (left_area < right_area || (left_area == right_area && node.entries.size <= sibling.entries.size)))
            node.add(entry)
          else
            sibling.add(entry)
          end
        end
        sibling
      end

      def split_seeds(entries)
        first = 0
        second = 1
        greatest_waste = nil
        entries.each_with_index do |entry, index|
          area = entry.bounds.area
          ((index + 1)...entries.size).each do |other_index|
            other = entries[other_index].bounds
            waste = entry.bounds.union_area(other) - area - other.area
            next unless greatest_waste.nil? || waste > greatest_waste

            greatest_waste = waste
            first = index
            second = other_index
          end
        end
        [first, second]
      end

      def split_next(entries, left, right)
        left_area = left.area
        right_area = right.area
        best_index = 0
        best_left = best_right = greatest_difference = nil
        entries.each_with_index do |entry, index|
          left_growth = left.union_area(entry.bounds) - left_area
          right_growth = right.union_area(entry.bounds) - right_area
          difference = (left_growth - right_growth).abs
          next unless greatest_difference.nil? || difference > greatest_difference

          greatest_difference = difference
          best_index = index
          best_left = left_growth
          best_right = right_growth
        end
        [best_index, best_left, best_right]
      end
    end
  end
end
