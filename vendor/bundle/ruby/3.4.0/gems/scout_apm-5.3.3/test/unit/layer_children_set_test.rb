require 'test_helper'
require 'scout_apm/layer_children_set'

class LayerChildrenSetTest < Minitest::Test
  SET = ScoutApm::LayerChildrenSet

  def test_limit_default
    assert_equal SET::DEFAULT_UNIQUE_CUTOFF, SET.new.unique_cutoff
  end

  # Add 5, make sure they're all in the children list we get back.
  def test_add_layer_before_limit
    s = SET.new(5)

    5.times do
      s << make_layer("LayerType", "LayerName")
    end

    children = s.to_a
    assert_equal 5, children.size

    # Don't care about order
    (0..4).each do |i|
      assert children.include?(lookup_layer(i))
    end
  end

  def test_add_layer_after_limit
    s = SET.new(5)

    10.times do
      s << make_layer("LayerType", "LayerName")
    end

    children = s.to_a
    # 6 = 5 real ones + 1 merged.
    assert_equal 6, children.size

    # Don't care about order
    (0..4).each do |i|
      assert children.include?(lookup_layer(i))
    end

    # Don't care about order
    (5..9).each do |i|
      assert ! children.include?(lookup_layer(i))
    end

    limited_layer = children.last
    assert_equal ScoutApm::LimitedLayer, limited_layer.class
    assert_equal 5, limited_layer.count
  end

  def test_add_layer_with_different_type_after_limit
    s = SET.new(5)

    # Add 20 items
    10.times do
      s << make_layer("LayerType", "LayerName")
      s << make_layer("DifferentLayerType", "LayerName")
    end

    children = s.to_a

    # Tyo types, so 2 distinct limitdlayer objects
    limited_layers = children.select{ |l| ScoutApm::LimitedLayer === l }
    assert_equal 2, limited_layers.length

    # 5 unchanged children each for the two layer types, plus the 2 limitd when each overran their limit
    assert_equal 12, children.length
    limited_layers.each { |ml| assert_equal 5, ml.count }
  end

  def test_works_with_marshal
    s = SET.new(5)
    10.times do
      s << make_layer("LayerType", "LayerName")
    end

    Marshal.dump(s)
  end

  #############
  #  Helpers  #
  #############

  def make_layer(type, name)
    @made_layers ||= []
    l = ScoutApm::Layer.new(type, name)
    @made_layers << l
    l
  end

  def lookup_layer(i)
    @made_layers[i]
  end
end
