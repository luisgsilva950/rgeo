# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Tests for Cartesian bounding boxes
#
# -----------------------------------------------------------------------------

require_relative "test_helper"

class CartesianBBoxTest < Minitest::Test # :nodoc:
  def setup
    @factory = RGeo::Cartesian.factory
  end

  def test_empty_bbox
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    assert_equal(true, bbox.empty?)
    assert_equal(false, bbox.has_z)
    assert_nil(bbox.min_x)
    assert_equal(@factory, bbox.factory)
    assert_nil(bbox.min_point)
    assert_equal(true, bbox.to_geometry.empty?)
    assert_equal(true, bbox.contains?(bbox))
    assert_equal(false, bbox.contains?(@factory.point(1, 1)))
    assert_nil(bbox.center_x)
    assert_equal(0, bbox.x_span)
    assert_equal(0, bbox.subdivide.size)
    assert_equal(false, bbox.infinitesimal?)
    assert_equal(false, bbox.degenerate?)
    assert_nil(bbox.max_point)
    assert_nil(bbox.center_y)
    assert_equal(0, bbox.y_span)
    assert_nil(bbox.z_span)
    assert_nil(bbox.m_span)
  end

  def test_point_bbox
    empty_bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 2))
    assert_equal(false, bbox.empty?)
    assert_equal(false, bbox.has_z)
    assert_equal(1.0, bbox.min_x)
    assert_equal(2.0, bbox.min_y)
    assert_equal(1.0, bbox.max_x)
    assert_equal(2.0, bbox.max_y)
    assert_equal(@factory, bbox.factory)
    assert_equal(@factory.point(1, 2), bbox.min_point)
    assert_equal(@factory.point(1, 2), bbox.max_point)
    assert_equal(@factory.point(1, 2), bbox.to_geometry)
    assert_equal(true, bbox.contains?(empty_bbox))
    assert_equal(false, empty_bbox.contains?(bbox))
    assert_equal(true, bbox.contains?(@factory.point(1, 2)))
    assert_equal(false, bbox.contains?(@factory.point(2, 1)))
    assert_equal(1, bbox.center_x)
    assert_equal(0, bbox.x_span)
    assert_equal(2, bbox.center_y)
    assert_equal(0, bbox.y_span)
    assert_equal([bbox], bbox.subdivide)
  end

  def test_rect_bbox
    empty_bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 4))
    bbox.add(@factory.point(2, 3))
    assert_equal(false, bbox.empty?)
    assert_equal(false, bbox.has_z)
    assert_equal(1.0, bbox.min_x)
    assert_equal(3.0, bbox.min_y)
    assert_equal(2.0, bbox.max_x)
    assert_equal(4.0, bbox.max_y)
    assert_equal(@factory, bbox.factory)
    assert_equal(@factory.point(1, 3), bbox.min_point)
    assert_equal(@factory.point(2, 4), bbox.max_point)
    assert_equal(1.0, bbox.to_geometry.area)
    assert_equal(true, bbox.contains?(empty_bbox))
    assert_equal(false, empty_bbox.contains?(bbox))
    assert_equal(true, bbox.contains?(@factory.point(1, 3)))
    assert_equal(false, bbox.contains?(@factory.point(2, 1)))
    assert_equal(1.5, bbox.center_x)
    assert_equal(1, bbox.x_span)
    assert_equal(3.5, bbox.center_y)
    assert_equal(1, bbox.y_span)
  end

  def test_bbox_from_points
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 4))
    bbox.add(@factory.point(2, 3))
    bbox2 = RGeo::Cartesian::BoundingBox.create_from_points(
      @factory.point(2, 3), @factory.point(1, 4)
    )
    assert_equal(bbox, bbox2)
  end

  def test_basic_rect_subdivide
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 2))
    bbox.add(@factory.point(5, 4))
    quads = bbox.subdivide
    quads.each { |q| assert_equal(2.0, q.to_geometry.area) }
    quadsum = quads[0].to_geometry + quads[1].to_geometry +
      quads[2].to_geometry + quads[3].to_geometry
    assert_equal(bbox.to_geometry, quadsum)
  end

  def test_horiz_line_subdivide
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 2))
    bbox.add(@factory.point(5, 2))
    lines = bbox.subdivide
    lines.each { |line| assert_equal(2.0, line.to_geometry.length) }
    linesum = lines[0].to_geometry + lines[1].to_geometry
    assert_equal(bbox.to_geometry, linesum)
  end

  def test_vert_line_subdivide
    bbox = RGeo::Cartesian::BoundingBox.new(@factory)
    bbox.add(@factory.point(1, 2))
    bbox.add(@factory.point(1, 6))
    lines = bbox.subdivide
    lines.each { |line| assert_equal(2.0, line.to_geometry.length) }
    linesum = lines[0].to_geometry + lines[1].to_geometry
    assert_equal(bbox.to_geometry, linesum)
  end

  def test_empty_geometries_and_boxes_do_not_change_bounds
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    empty = RGeo::Cartesian::BoundingBox.new(factory)
    geometries = [factory.collection([]), factory.line_string([]),
                  factory.polygon(factory.linear_ring([])), factory.multi_point([]),
                  factory.multi_line_string([]), factory.multi_polygon([])]
    geometries.each do |geometry|
      assert_same(empty, empty.add(geometry))
      assert_equal(true, empty.empty?)
      assert_equal(true, empty.contains?(geometry))
    end
    assert_equal(0, empty.z_span)
    assert_equal(0, empty.m_span)
    assert_nil(empty.center_z)
    assert_nil(empty.center_m)
    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(factory.point(1, 2, 3, 4))
    expected = bbox.dup
    assert_same(bbox, bbox.add(empty))
    assert_equal(expected, bbox)
    assert_same(empty, empty.add(bbox))
    assert_equal(bbox, empty)
  end

  def test_dimension_bounds_and_constructor_options
    [RGeo::Cartesian.method(:simple_factory), RGeo::Cartesian.method(:factory)].each do |create_factory|
      factory = create_factory.call(has_z_coordinate: true, has_m_coordinate: true)
      points = [factory.point(4, 8, 12, 16), factory.point(-2, -4, -6, -8)]
      [{}, { ignore_z: true }, { ignore_m: true }, { ignore_z: true, ignore_m: true }].each do |opts|
        bbox = RGeo::Cartesian::BoundingBox.create_from_points(*points, opts)
        geometry_bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(factory.line_string(points), opts)
        assert_equal(bbox, geometry_bbox)
        assert_equal(!opts[:ignore_z], bbox.has_z)
        assert_equal(!opts[:ignore_m], bbox.has_m)
        assert_equal([-2, 4, -4, 8], [bbox.min_x, bbox.max_x, bbox.min_y, bbox.max_y])
        assert_equal(1, bbox.center_x)
        assert_equal(2, bbox.center_y)
        expected_z = opts[:ignore_z] ? [nil, nil, nil, nil] : [-6, 12, 3, 18]
        expected_m = opts[:ignore_m] ? [nil, nil, nil, nil] : [-8, 16, 4, 24]
        assert_equal(expected_z, [bbox.min_z, bbox.max_z, bbox.center_z, bbox.z_span])
        assert_equal(expected_m, [bbox.min_m, bbox.max_m, bbox.center_m, bbox.m_span])
        assert_equal([-2, -4, opts[:ignore_z] ? 0 : -6, opts[:ignore_m] ? 0 : -8],
                     bbox.min_point.coordinates)
        assert_equal([4, 8, opts[:ignore_z] ? 0 : 12, opts[:ignore_m] ? 0 : 16],
                     bbox.max_point.coordinates)
      end
    end
  end

  def test_containment_dimension_options_match_for_geometries_and_boxes
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    bbox = RGeo::Cartesian::BoundingBox.create_from_points(factory.point(0, 0, 0, 0),
                                                           factory.point(4, 4, 4, 4))
    cases = [[factory.point(2, 2, 2, 2), {}, true],
             [factory.point(2, 2, 8, 2), {}, false],
             [factory.point(2, 2, 8, 2), { ignore_z: true }, true],
             [factory.point(2, 2, 2, 8), {}, false],
             [factory.point(2, 2, 2, 8), { ignore_m: true }, true],
             [factory.point(2, 2, 8, 8), { ignore_z: true }, false],
             [factory.point(2, 2, 8, 8), { ignore_m: true }, false],
             [factory.point(2, 2, 8, 8), { ignore_z: true, ignore_m: true }, true],
             [factory.point(8, 2, 8, 8), { ignore_z: true, ignore_m: true }, false],
             [factory.point(0, 4, 0, 4), {}, true]]
    cases.each do |point, opts, expected|
      geometries = [point, factory.line_string([point, point]),
                    factory.collection([factory.collection([point])])]
      geometries.each do |geometry|
        assert_equal(expected, bbox.contains?(geometry, opts))
        assert_equal(expected, bbox.contains?(RGeo::Cartesian::BoundingBox.create_from_geometry(geometry), opts))
      end
    end
  end

  def test_ignored_z_preserves_m_in_envelopes_and_box_merges
    [RGeo::Cartesian.method(:simple_factory), RGeo::Cartesian.method(:factory)].each do |create_factory|
      factory = create_factory.call(has_z_coordinate: true, has_m_coordinate: true)
      [[0, 0], [0, 2], [2, 0], [2, 2]].each do |x, y|
        bbox = RGeo::Cartesian::BoundingBox.create_from_points(factory.point(0, 0, 1, 10),
                                                               factory.point(x, y, 3, 20), ignore_z: true)
        envelope = bbox.to_geometry
        assert_equal(factory, envelope.factory)
        envelope_bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(envelope, ignore_z: true)
        assert_equal(10, envelope_bbox.min_m)
        assert_equal(x.zero? && y.zero? ? 10 : 20, envelope_bbox.max_m)
        merged = RGeo::Cartesian::BoundingBox.new(factory, ignore_z: true).add(bbox)
        assert_equal(bbox, merged)
      end
    end
  end

  def test_polygon_interior_rings_contribute_dimension_extents
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    exterior = factory.linear_ring([[0, 0], [4, 0], [4, 4], [0, 4], [0, 0]].map do |x, y|
      factory.point(x, y, 1, 2)
    end)
    interior_coords = [[1, 1, -3, -4], [1, 2, 5, 6], [2, 2, 5, 6],
                       [2, 1, -3, -4], [1, 1, -3, -4]]
    interior = factory.linear_ring(interior_coords.map { |coords| factory.point(*coords) })
    polygon = factory.polygon(exterior, [interior])
    geometries = [polygon, factory.multi_polygon([polygon]),
                  factory.collection([factory.multi_polygon([polygon])])]
    geometries.each do |geometry|
      bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
      assert_equal([0, 4, 0, 4, -3, 5, -4, 6],
                   [bbox.min_x, bbox.max_x, bbox.min_y, bbox.max_y, bbox.min_z, bbox.max_z, bbox.min_m, bbox.max_m])
      assert_equal(true, bbox.contains?(interior))
      unless geometry.geometry_type == RGeo::Feature::GeometryCollection
        assert_equal(bbox, RGeo::Cartesian::BoundingBox.create_from_geometry(geometry.boundary))
      end
    end
  end

  def test_geometry_collection_matches_adding_components
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    point1 = factory.point(-1, -2, -3, -4)
    point2 = factory.point(4, 6, 8, 10)
    points = [point1, point2]
    line = factory.line_string(points)
    ring = factory.linear_ring([point1, factory.point(4, -2, 0, 0), point2, point1])
    polygon = factory.polygon(ring)
    geometries = [point1, line, ring, polygon, factory.multi_point(points),
                  factory.multi_line_string([line]), factory.multi_polygon([polygon]),
                  factory.collection([factory.collection([point2])])]
    expected = RGeo::Cartesian::BoundingBox.create_from_points(*points)
    geometries.each do |geometry|
      bbox = RGeo::Cartesian::BoundingBox.new(factory).add(point1).add(geometry).add(point2)
      assert_equal(expected, bbox)
    end
    assert_equal(expected, RGeo::Cartesian::BoundingBox.create_from_geometry(factory.collection(geometries)))
  end

  def test_adding_geometry_and_box_casts_to_destination_factory
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true, srid: 100)
    source = RGeo::Cartesian.simple_factory(has_m_coordinate: true, srid: 200)
    geometry = source.line_string([source.point(-1, 2, 3), source.point(4, -5, 6)])
    expected = RGeo::Cartesian::BoundingBox.new(factory).add(RGeo::Feature.cast(geometry, factory))
    assert_equal(expected, RGeo::Cartesian::BoundingBox.new(factory).add(geometry))
    source_bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    assert_equal(expected, RGeo::Cartesian::BoundingBox.new(factory).add(source_bbox))
    bbox = RGeo::Cartesian::BoundingBox.create_from_points(factory.point(-1, 2, 0, 3),
                                                           source.point(4, -5, 6))
    assert_equal(expected, bbox)
  end

  def test_subdivision_bisects_long_axes_and_preserves_dimensions
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    [[8, 2, 2], [2, 8, 2], [4, 2, 4]].each do |x, y, count|
      bbox = RGeo::Cartesian::BoundingBox.create_from_points(factory.point(0, 0, -3, -4),
                                                             factory.point(x, y, 5, 6))
      parts = bbox.subdivide(bisect_factor: 2)
      assert_equal(count, parts.size)
      assert_equal(x * y, parts.sum { |part| part.x_span * part.y_span })
      parts.each do |part|
        assert_equal(true, bbox.contains?(part))
        assert_equal([-3, 5, -4, 6], [part.min_z, part.max_z, part.min_m, part.max_m])
      end
      ignored = RGeo::Cartesian::BoundingBox.create_from_geometry(bbox.to_geometry, ignore_z: true)
      ignored.subdivide(bisect_factor: 2).each do |part|
        assert_equal(false, part.has_z)
        assert_equal(true, part.has_m)
        assert_nil(part.min_z)
        assert_equal([-4, 6], [part.min_m, part.max_m])
      end
    end
  end

  def test_single_dimension_factories_preserve_supported_coordinates
    [{}, { has_z_coordinate: true }, { has_m_coordinate: true }].each do |factory_opts|
      factory = RGeo::Cartesian.simple_factory(factory_opts)
      extras = factory_opts.empty? ? [] : [3]
      point = factory.point(1, 2, *extras)
      bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(point)
      assert_equal(point.coordinates, bbox.min_point.coordinates)
      assert_equal(point.coordinates, bbox.max_point.coordinates)
      assert_equal(point.coordinates, bbox.to_geometry.coordinates)
      assert_equal(true, bbox.infinitesimal?)
      assert_equal(true, bbox.degenerate?)
      assert_equal(true, bbox.contains?(point))
      assert_equal([bbox], bbox.subdivide)
      ignored = RGeo::Cartesian::BoundingBox.create_from_geometry(point, ignore_z: true, ignore_m: true)
      assert_equal(false, ignored.has_z)
      assert_equal(false, ignored.has_m)
      assert_nil(ignored.min_z)
      assert_nil(ignored.min_m)
      expected_coordinates = factory_opts.empty? ? [1, 2] : [1, 2, 0]
      assert_equal(expected_coordinates, ignored.min_point.coordinates)
      assert_equal(expected_coordinates, ignored.max_point.coordinates)
      assert_equal(expected_coordinates, ignored.to_geometry.coordinates)
    end
  end
end
