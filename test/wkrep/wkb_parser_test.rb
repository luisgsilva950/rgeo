# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Tests for WKT parser
#
# -----------------------------------------------------------------------------

require_relative "../test_helper"

class WKBParserTest < Minitest::Test # :nodoc:
  def test_point_2d_xdr_hex
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("00000000013ff00000000000004000000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(1, obj.x)
    assert_equal(2, obj.y)
  end

  def test_point_2d_xdr_binary
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse(["00000000013ff00000000000004000000000000000"].pack("H*"))
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(1, obj.x)
    assert_equal(2, obj.y)
  end

  def test_point_2d_ndr
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("0101000000000000000000f03f0000000000000040")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(1, obj.x)
    assert_equal(2, obj.y)
  end

  def test_point_with_ewkb_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    obj = parser.parse("00800000013ff000000000000040000000000000004008000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.z)
    assert_nil(obj.m)
  end

  def test_point_with_ewkb_m
    factory_ = RGeo::Cartesian.preferred_factory(has_m_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    obj = parser.parse("00400000013ff000000000000040000000000000004008000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.m)
    assert_nil(obj.z)
  end

  def test_point_with_ewkb_zm
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true, has_m_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    obj = parser.parse("00c00000013ff0000000000000400000000000000040080000000000004010000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.z)
    assert_equal(4, obj.m)
  end

  def test_point_with_wkb12_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_wkb12: true)
    obj = parser.parse("00000003e93ff000000000000040000000000000004008000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.z)
    assert_nil(obj.m)
  end

  def test_point_with_wkb12_m
    factory_ = RGeo::Cartesian.preferred_factory(has_m_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_wkb12: true)
    obj = parser.parse("00000007d13ff000000000000040000000000000004008000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.m)
    assert_nil(obj.z)
  end

  def test_point_with_wkb12_zm
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true, has_m_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_wkb12: true)
    obj = parser.parse("0000000bb93ff0000000000000400000000000000040080000000000004010000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.z)
    assert_equal(4, obj.m)
  end

  def test_point_with_wkb12_z_without_wkb12_support
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_)
    assert_raises(RGeo::Error::ParseError) do
      parser.parse("00000003e93ff000000000000040000000000000004008000000000000")
    end
  end

  def test_point_with_wkb12_z_without_enough_data
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_wkb12: true)
    assert_raises(RGeo::Error::ParseError) do
      parser.parse("00000003e93ff00000000000004000000000000000")
    end
  end

  def test_point_with_ewkb_z_and_srid
    factory_generator_ = proc do |config_|
      RGeo::Cartesian.preferred_factory(has_z_coordinate: true, srid: config_[:srid])
    end
    parser = RGeo::WKRep::WKBParser.new(factory_generator_, support_ewkb: true)
    obj = parser.parse("00a0000001000003e83ff000000000000040000000000000004008000000000000")
    assert_equal(RGeo::Feature::Point, obj.geometry_type)
    assert_equal(3, obj.z)
    assert_nil(obj.m)
    assert_equal(1000, obj.srid)
  end

  def test_linestring_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "0000000002000000033ff00000000000004000000000000000400800000000000040100000000000004014000000000000" \
            "4018000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::LineString, obj.geometry_type)
    assert_equal(3, obj.num_points)
    assert_equal(1, obj.point_n(0).x)
    assert_equal(6, obj.point_n(2).y)
  end

  def test_linestring_with_ewkb_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    input = "0080000002000000023ff00000000000004000000000000000400800000000000040100000000000004014000000000000" \
            "4018000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::LineString, obj.geometry_type)
    assert_equal(2, obj.num_points)
    assert_equal(1, obj.point_n(0).x)
    assert_equal(6, obj.point_n(1).z)
  end

  def test_linestring_with_ewkb_z_and_srid
    factory_generator_ = proc do |config_|
      RGeo::Cartesian.preferred_factory(has_z_coordinate: true, srid: config_[:srid])
    end
    parser = RGeo::WKRep::WKBParser.new(factory_generator_, support_ewkb: true)
    input = "00a0000002000003e8000000023ff0000000000000400000000000000040080000000000004010000000000000401400000000" \
            "00004018000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::LineString, obj.geometry_type)
    assert_equal(2, obj.num_points)
    assert_equal(1, obj.point_n(0).x)
    assert_equal(6, obj.point_n(1).z)
    assert_equal(1000, obj.srid)
  end

  def test_linestring_with_wkb12_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_wkb12: true)
    input = "00000003ea000000023ff00000000000004000000000000000400800000000000040100000000000004014000000000000" \
            "4018000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::LineString, obj.geometry_type)
    assert_equal(2, obj.num_points)
    assert_equal(1, obj.point_n(0).x)
    assert_equal(6, obj.point_n(1).z)
  end

  def test_linestring_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000200000000")
    assert_equal(RGeo::Feature::LineString, obj.geometry_type)
    assert_equal(0, obj.num_points)
  end

  def test_polygon_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "000000000300000001000000043ff0000000000000400000000000000040080000000000004010000000000000401800000000" \
            "000040140000000000003ff00000000000004000000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::Polygon, obj.geometry_type)
    assert_equal(4, obj.exterior_ring.num_points)
    assert_equal(1, obj.exterior_ring.point_n(0).x)
    assert_equal(5, obj.exterior_ring.point_n(2).y)
  end

  def test_polygon_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000300000000")
    assert_equal(RGeo::Feature::Polygon, obj.geometry_type)
    assert_equal(0, obj.exterior_ring.num_points)
  end

  def test_multipoint_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "00000000040000000200000000013ff00000000000004000000000000000000000000140080000000000004010000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::MultiPoint, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(1, obj[0].x)
    assert_equal(4, obj[1].y)
  end

  def test_multipoint_mixed_byte_order
    parser = RGeo::WKRep::WKBParser.new
    input = "0000000004000000020101000000000000000000f03f0000000000000040000000000140080000000000004010000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::MultiPoint, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(1, obj[0].x)
    assert_equal(4, obj[1].y)
  end

  def test_multipoint_with_ewkb_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    input = "00800000040000000200800000013ff00000000000004000000000000000401400000000000000800000014008000000000000" \
            "40100000000000004018000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::MultiPoint, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(1, obj[0].x)
    assert_equal(5, obj[0].z)
    assert_equal(4, obj[1].y)
    assert_equal(6, obj[1].z)
    assert_nil(obj[0].m)
  end

  def test_multipoint_ewkb_with_mixed_z
    factory_ = RGeo::Cartesian.preferred_factory(has_z_coordinate: true)
    parser = RGeo::WKRep::WKBParser.new(factory_, support_ewkb: true)
    input = "00800000040000000200800000013ff00000000000004000000000000000401400000000000000000000014008000000000000" \
            "4010000000000000"
    assert_raises(RGeo::Error::ParseError) do
      parser.parse(input)
    end
  end

  def test_multipoint_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000400000000")
    assert_equal(RGeo::Feature::MultiPoint, obj.geometry_type)
    assert_equal(0, obj.num_geometries)
  end

  def test_multilinestring_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "0000000005000000020000000002000000033ff000000000000040000000000000004008000000000000401000000000000040" \
            "140000000000004018000000000000000000000200000002bff0000000000000c000000000000000c008000000000000c01000" \
            "0000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::MultiLineString, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(1, obj[0].point_n(0).x)
    assert_equal(-4, obj[1].point_n(1).y)
  end

  def test_multilinestring_wrong_element_type
    parser = RGeo::WKRep::WKBParser.new
    input = "0000000005000000020000000002000000033ff000000000000040000000000000004008000000000000401000000000000040" \
            "14000000000000401800000000000000000000013ff00000000000004000000000000000"
    assert_raises(RGeo::Error::ParseError) do
      parser.parse(input)
    end
  end

  def test_multilinestring_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000500000000")
    assert_equal(RGeo::Feature::MultiLineString, obj.geometry_type)
    assert_equal(0, obj.num_geometries)
  end

  def test_multipolygon_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "000000000600000002000000000300000001000000043ff0000000000000400000000000000040080000000000004010000000" \
            "000000401800000000000040140000000000003ff00000000000004000000000000000000000000300000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::MultiPolygon, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(4, obj[0].exterior_ring.num_points)
    assert_equal(1, obj[0].exterior_ring.point_n(0).x)
    assert_equal(5, obj[0].exterior_ring.point_n(2).y)
    assert_equal(0, obj[1].exterior_ring.num_points)
  end

  def test_multipolygon_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000600000000")
    assert_equal(RGeo::Feature::MultiPolygon, obj.geometry_type)
    assert_equal(0, obj.num_geometries)
  end

  def test_collection_basic
    parser = RGeo::WKRep::WKBParser.new
    input = "0000000007000000020000000002000000033ff0000000000000400000000000000040080000000000004010000000000000" \
            "401400000000000040180000000000000000000001bff0000000000000c000000000000000"
    obj = parser.parse(input)
    assert_equal(RGeo::Feature::GeometryCollection, obj.geometry_type)
    assert_equal(2, obj.num_geometries)
    assert_equal(RGeo::Feature::LineString, obj[0].geometry_type)
    assert_equal(1, obj[0].point_n(0).x)
    assert_equal(6, obj[0].point_n(2).y)
    assert_equal(RGeo::Feature::Point, obj[1].geometry_type)
    assert_equal(-1, obj[1].x)
  end

  def test_collection_empty
    parser = RGeo::WKRep::WKBParser.new
    obj = parser.parse("000000000700000000")
    assert_equal(RGeo::Feature::GeometryCollection, obj.geometry_type)
    assert_equal(0, obj.num_geometries)
  end

  def test_invalid_hexadecimal_input
    factory = RGeo::Cartesian.simple_factory
    hex = RGeo::WKRep::WKBGenerator.new(hex_format: true).generate(factory.point(1, 2))
    parser = RGeo::WKRep::WKBParser.new(factory)
    [hex[0...-1], "#{hex[0...-1]}g", "#{hex} ", "#{hex}\n", "#{hex[0...-2]}é",
     "#{hex[0...-1]}\xff".b].each do |input|
      assert_raises(RGeo::Error::ParseError) { parser.parse(input) }
    end
    assert_equal(factory.point(1, 2), parser.parse(hex.upcase))
  end

  def test_invalid_hexadecimal_input_with_extra_bytes_ignored
    parser = RGeo::WKRep::WKBParser.new(nil, ignore_extra_bytes: true)
    assert_raises(RGeo::Error::ParseError) do
      parser.parse("00000000013ff0000000000000400000000000000")
    end
  end

  def test_binary_input_uses_bytes_regardless_of_encoding
    factory = RGeo::Cartesian.simple_factory
    parser = RGeo::WKRep::WKBParser.new(factory)
    data = [0, 1, 0.0, 0.0].pack("CNGG")
    data[-2, 2] = "é"
    expected = parser.parse(data.b)
    [Encoding::UTF_8, Encoding::UTF_16LE].each do |encoding|
      input = data.dup.force_encoding(encoding).freeze
      assert_equal(expected, parser.parse(input))
      assert_equal(encoding, input.encoding)
    end
  end

  def test_invalid_byte_order_at_toplevel_and_in_collection
    parser = RGeo::WKRep::WKBParser.new
    [2, 255].each do |byte_order|
      invalid = [byte_order, 1, 1.0, 2.0].pack("CNGG")
      [invalid, [0, 7, 1].pack("CNN") + invalid].each do |input|
        assert_raises(RGeo::Error::ParseError) { parser.parse(input) }
      end
    end
  end

  def test_unsupported_type_codes
    parser = RGeo::WKRep::WKBParser.new(nil, support_ewkb: true, support_wkb12: true)
    [0, 8, 15, 4001, 5001, 6001, 7001, 8001, 0x10000001, 0x90000001, 0x100003e9].each do |type|
      [false, true].each do |little_endian|
        input = if little_endian
                  [1, type, 1.0, 2.0, 3.0, 4.0].pack("CVEEEE")
                else
                  [0, type, 1.0, 2.0, 3.0, 4.0].pack("CNGGGG")
                end
        assert_raises(RGeo::Error::ParseError) { parser.parse(input) }
      end
    end
  end

  def test_extended_dimensions_require_enabled_format_and_factory_support
    %i[ewkb wkb12].each do |format|
      [{ has_z_coordinate: true }, { has_m_coordinate: true }].each do |dimensions|
        factory = RGeo::Cartesian.simple_factory(**dimensions)
        data = RGeo::WKRep::WKBGenerator.new(type_format: format).generate(factory.point(1, 2, 3))
        assert_raises(RGeo::Error::ParseError) { RGeo::WKRep::WKBParser.new(factory).parse(data) }
        parser = RGeo::WKRep::WKBParser.new(RGeo::Cartesian.simple_factory,
                                            support_ewkb: true, support_wkb12: true)
        assert_raises(RGeo::Error::ParseError) { parser.parse(data) }
      end
    end
  end

  def test_generated_geometries_round_trip_all_formats_dimensions_and_byte_orders
    [{}, { has_z_coordinate: true }, { has_m_coordinate: true },
     { has_z_coordinate: true, has_m_coordinate: true }].each do |dimensions|
      factory = RGeo::Cartesian.simple_factory(**dimensions, srid: 4326)
      %i[wkb11 ewkb wkb12].each do |format|
        next if format == :wkb11 && !dimensions.empty?

        [false, true].each do |little_endian|
          [false, true].each do |hex_format|
            generator = RGeo::WKRep::WKBGenerator.new(type_format: format, little_endian:,
                                                      hex_format:, emit_ewkb_srid: true)
            parser = RGeo::WKRep::WKBParser.new(RGeo::Cartesian.method(:simple_factory),
                                                support_ewkb: true, support_wkb12: true, default_srid: 4326)
            wkb_geometries(factory).each do |geometry|
              assert_equal(geometry, parser.parse(generator.generate(geometry)))
            end
          end
        end
      end
    end
  end

  def test_m_only_coordinates_preserved_by_zm_factory
    m_factory = RGeo::Cartesian.simple_factory(has_m_coordinate: true)
    zm_factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true)
    expected = wkb_geometries(zm_factory, m_only: true)
    parser = RGeo::WKRep::WKBParser.new(zm_factory, support_ewkb: true, support_wkb12: true)
    %i[ewkb wkb12].each do |format|
      [false, true].each do |little_endian|
        generator = RGeo::WKRep::WKBGenerator.new(type_format: format, little_endian:)
        wkb_geometries(m_factory).each_with_index do |geometry, index|
          assert_equal(expected[index], parser.parse(generator.generate(geometry)))
        end
      end
    end
  end

  def test_truncated_generated_geometries_and_recovery
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true, srid: 4326)
    parser = RGeo::WKRep::WKBParser.new(factory, support_ewkb: true)
    [false, true].each do |little_endian|
      generator = RGeo::WKRep::WKBGenerator.new(type_format: :ewkb, emit_ewkb_srid: true,
                                                little_endian:)
      wkb_geometries(factory).each do |geometry|
        data = generator.generate(geometry)
        data.bytesize.times do |length|
          assert_raises(RGeo::Error::ParseError) { parser.parse(data.byteslice(0, length)) }
        end
        assert_equal(geometry, parser.parse(data))
      end
    end
  end

  def test_huge_counts_without_payload
    parser = RGeo::WKRep::WKBParser.new
    (2..7).each do |type|
      assert_raises(RGeo::Error::ParseError) { parser.parse([0, type, 0xffffffff].pack("CNN")) }
    end
  end

  def test_trailing_bytes_and_recovery
    factory = RGeo::Cartesian.simple_factory
    point = factory.point(1, 2)
    data = RGeo::WKRep::WKBGenerator.new.generate(point)
    parser = RGeo::WKRep::WKBParser.new(factory)
    assert_raises(RGeo::Error::ParseError) { parser.parse("#{data}extra") }
    assert_equal(point, parser.parse(data))
    parser = RGeo::WKRep::WKBParser.new(factory, ignore_extra_bytes: true)
    assert_equal(point, parser.parse("#{data}extra"))
    assert_raises(RGeo::Error::ParseError) { parser.parse(data.byteslice(0, data.bytesize - 1)) }
  end

  def test_nested_mixed_byte_order_dimensions_and_srid
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true, srid: 4326)
    point = factory.point(1, 2, 3, 4)
    parser = RGeo::WKRep::WKBParser.new(RGeo::Cartesian.method(:simple_factory), support_ewkb: true)
    [false, true].each do |little_endian|
      generator = RGeo::WKRep::WKBGenerator.new(type_format: :ewkb, emit_ewkb_srid: true,
                                                little_endian: !little_endian)
      nested = generator.generate(factory.collection([point]))
      header = if little_endian
                 [1, 0xe0000007, 4326, 1].pack("CVVV")
               else
                 [0, 0xe0000007, 4326, 1].pack("CNNN")
               end
      assert_equal(factory.collection([factory.collection([point])]), parser.parse(header + nested))
    end
  end

  def test_nested_m_and_srid_mismatches
    factory = RGeo::Cartesian.simple_factory(has_m_coordinate: true, srid: 4326)
    generator = RGeo::WKRep::WKBGenerator.new(type_format: :ewkb, emit_ewkb_srid: true)
    point = generator.generate(factory.point(1, 2, 3))
    parser = RGeo::WKRep::WKBParser.new(RGeo::Cartesian.method(:simple_factory), support_ewkb: true)
    [[0, 0x20000007, 4326, 1], [0, 0x60000007, 1000, 1]].each do |header|
      assert_raises(RGeo::Error::ParseError) { parser.parse(header.pack("CNNN") + point) }
    end
    assert_raises(RGeo::Error::ParseError) { parser.parse([0, 0x40000007, 1].pack("CNN") + point) }
    assert_equal(factory.point(1, 2, 3), parser.parse(point))
  end

  def test_parser_recovery_resets_dimensions_and_srid
    factory = RGeo::Cartesian.simple_factory(has_z_coordinate: true, has_m_coordinate: true, srid: 4326)
    generator = RGeo::WKRep::WKBGenerator.new(type_format: :ewkb, emit_ewkb_srid: true)
    data = generator.generate(factory.point(1, 2, 3, 4))
    parser = RGeo::WKRep::WKBParser.new(RGeo::Cartesian.method(:simple_factory),
                                        support_ewkb: true, default_srid: 1000)
    assert_equal(factory.point(1, 2, 3, 4), parser.parse(data))
    assert_raises(RGeo::Error::ParseError) { parser.parse(data.byteslice(0, data.bytesize - 1)) }
    plain_factory = RGeo::Cartesian.simple_factory(srid: 1000)
    plain_point = plain_factory.point(5, 6)
    assert_equal(plain_point, parser.parse(RGeo::WKRep::WKBGenerator.new.generate(plain_point)))
    assert_equal(factory.point(1, 2, 3, 4), parser.parse(data))
  end

  def test_multithreaded
    parser = RGeo::WKRep::WKBParser.new
    data = fixtures.join("isere.wkb").binread
    Array.new(100) do
      Thread.fork do
        parser.parse(data)
      end
    end.map(&:join)
  end

  private

  def wkb_geometries(factory, m_only: false)
    points = [[1, 2, 3, 4], [3, 4, 5, 6], [6, 5, 7, 8]].map do |coords|
      if m_only
        factory.point(coords[0], coords[1], 0, coords[2])
      else
        dimensions = 2 + (factory.property(:has_z_coordinate) ? 1 : 0) +
                     (factory.property(:has_m_coordinate) ? 1 : 0)
        factory.point(*coords.first(dimensions))
      end
    end
    line = factory.line_string(points)
    polygon = factory.polygon(factory.linear_ring(points + [points.first]))
    [points.first, line, polygon, factory.multi_point(points), factory.multi_line_string([line]),
     factory.multi_polygon([polygon]), factory.collection([points.first, factory.collection([line, polygon])]),
     factory.line_string([]), factory.polygon(factory.linear_ring([])), factory.multi_point([]),
     factory.multi_line_string([]), factory.multi_polygon([]), factory.collection([])]
  end
end
