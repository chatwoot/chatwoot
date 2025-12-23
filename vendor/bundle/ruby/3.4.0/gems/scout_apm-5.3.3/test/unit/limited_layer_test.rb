require 'test_helper'
require 'ostruct'

class LimitedLayerTest < Minitest::Test

  def test_counts_while_absorbing
    ll = ScoutApm::LimitedLayer.new("ActiveRecord")
    assert_equal 0, ll.count

    ll.absorb faux_layer("ActiveRecord", "User#Find", 2, 1, 200, 100)
    assert_equal 1, ll.count

    ll.absorb faux_layer("ActiveRecord", "User#Find", 2, 1, 200, 100)
    assert_equal 2, ll.count
  end

  def test_sums_values_while_absorbing
    ll = ScoutApm::LimitedLayer.new("ActiveRecord")

    ll.absorb faux_layer("ActiveRecord", "User#Find", 2, 1, 200, 100)
    assert_equal 1, ll.total_exclusive_time
    assert_equal 2, ll.total_call_time
    assert_equal 100, ll.total_exclusive_allocations
    assert_equal 200, ll.total_allocations


    ll.absorb faux_layer("ActiveRecord", "User#Find", 4, 3, 400, 300)
    assert_equal 4, ll.total_exclusive_time           # 3 + 1
    assert_equal 6, ll.total_call_time                # 4 + 2
    assert_equal 400, ll.total_exclusive_allocations  # 300 + 100
    assert_equal 600, ll.total_allocations            # 400 + 200
  end

  def test_the_name
    ll = ScoutApm::LimitedLayer.new("ActiveRecord")
    assert_equal "ActiveRecord/Limited", ll.legacy_metric_name
  end

  #############
  #  Helpers  #
  #############

  def faux_layer(type, name, tct, tet, a_tct, a_tet)
    OpenStruct.new(
      :type => type,
      :name => name,
      :total_call_time => tct,
      :total_exclusive_time => tet,
      :total_allocations => a_tct,
      :total_exclusive_allocations => a_tet
    )
  end
end
