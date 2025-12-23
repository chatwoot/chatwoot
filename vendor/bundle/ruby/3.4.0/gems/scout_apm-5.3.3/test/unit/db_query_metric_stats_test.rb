require 'test_helper'

require 'scout_apm/db_query_metric_stats'

module ScoutApm
class DbQueryMetricStatsTest < Minitest::Test
  def test_as_json_empty_stats
    stat = build("table", "op", "Controller/public/index", 1, 10, 20)

    assert_equal({
      :model_name => "table",
      :operation => "op",
      :call_count => 1,
      :transaction_count => 0,
      :scope => "Controller/public/index",
      :histogram => [[10.0, 1]],

      :max_call_time => 10.0,
      :min_call_time => 10.0,
      :call_time => 10.0,

      :max_rows_returned => 20,
      :min_rows_returned => 20,
      :rows_returned => 20,
    }, stat.as_json)
  end

  def test_increment_transaction_count
    stat = build()
    assert_equal 0, stat.transaction_count

    stat.increment_transaction_count!

    assert_equal 1, stat.transaction_count
  end

  def test_key_name
    stat = build("User", "find", "Controller/public/index")
    assert_equal ["User", "find", "Controller/public/index"], stat.key
  end

  def test_combine_min_call_time_picks_smallest
    stat1, stat2 = build_pair
    assert_equal 5.1,  stat1.combine!(stat2).min_call_time
  end

  def test_combine_max_call_time_picks_largest
    stat1, stat2 = build_pair
    assert_equal 8.2,  stat1.combine!(stat2).max_call_time
  end

  def test_combine_call_counts_adds
    stat1, stat2 = build_pair
    assert_equal 5, stat1.combine!(stat2).call_count
  end

  def test_combine_transaction_count_adds
    stat1, stat2 = build_pair
    2.times { stat1.increment_transaction_count! }
    3.times { stat2.increment_transaction_count! }

    assert_equal 5, stat1.combine!(stat2).call_count
  end

  def test_combine_doesnt_merge_with_self
    stat = build
    merged = stat.combine!(stat)

    assert_equal DEFAULTS[:call_count], merged.call_count
    assert_equal DEFAULTS[:call_time], merged.call_time
    assert_equal DEFAULTS[:rows_returned], merged.rows_returned
  end

  # A.combine!(B) should be the the same as B.combine!(A)
  # Have to be a bit careful, since combine! is destructive, so make two pairs
  # with same data to do both sides, then check that they result in the same
  # answer
  [:transaction_count, :call_count, :rows_returned, :min_rows_returned, :max_rows_returned, :max_call_time, :min_call_time].each do |attr|
    define_method :"test_combine_#{attr}_is_symmetric" do
      stat1_a, stat2_a = build_pair
      stat1_b, stat2_b = build_pair
      merged_a = stat1_a.combine!(stat2_a)
      merged_b = stat2_b.combine!(stat1_b)

      assert_equal merged_a.send(attr), merged_b.send(attr)
    end
  end

  #############
  #  Helpers  #
  #############
  DEFAULTS = {
    :call_count => 1,
    :call_time => 10.0,
    :rows_returned => 20,
  }

  def build(model_name="User",
            operation="find",
            scope="Controller/public/index",
            call_count=DEFAULTS[:call_count],
            call_time=DEFAULTS[:call_time],
            rows_returned=DEFAULTS[:rows_returned])
    DbQueryMetricStats.new(model_name, operation, scope, call_count, call_time, rows_returned)
  end

  def build_pair
    stat1 = build("table", "op", "Controller/public/index", 2, 5.1, 10)
    stat2 = build("table", "op", "Controller/public/index", 3, 8.2, 20)
    [stat1, stat2]
  end
end
end
