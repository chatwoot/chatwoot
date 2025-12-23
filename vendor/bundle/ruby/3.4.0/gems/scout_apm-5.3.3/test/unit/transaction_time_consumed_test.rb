require 'test_helper'

require 'scout_apm/transaction_time_consumed'

module ScoutApm
  class TransactionTimeConsumedTest < Minitest::Test
    def setup
      @ttc = ScoutApm::TransactionTimeConsumed.new
    end

    def test_insert_new_times
      @ttc.add("Controller/Foo", 1.5)
      @ttc.add("Controller/Foo", 2.75)
      assert_equal 4.25, @ttc.total_time_for("Controller/Foo")
    end

    def test_insert_tracks_endpoints_separately
      @ttc.add("Controller/Foo", 1.5)
      @ttc.add("Controller/Foo", 2.75)
      @ttc.add("Controller/Bar", 5)
      @ttc.add("Controller/Bar", 5)
      assert_equal 4.25, @ttc.total_time_for("Controller/Foo")
      assert_equal 10.0, @ttc.total_time_for("Controller/Bar")
    end

    def test_calculates_percent_of_total
      @ttc.add("Controller/Foo", 1)
      @ttc.add("Controller/Bar", 4)
      assert_equal 0.2, @ttc.percent_of_total("Controller/Foo")
      assert_equal 0.8, @ttc.percent_of_total("Controller/Bar")
    end

    def test_counts_total_call_count
      @ttc.add("Controller/Foo", 1)
      @ttc.add("Controller/Foo", 1)
      @ttc.add("Controller/Foo", 1)
      @ttc.add("Controller/Bar", 4)
      assert_equal 3, @ttc.call_count_for("Controller/Foo")
      assert_equal 1, @ttc.call_count_for("Controller/Bar")
    end

    def test_percent_of_total_is_0_with_no_data
      assert_equal 0.0, @ttc.percent_of_total("Controller/Foo")
    end
  end
end
