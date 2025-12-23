require 'test_helper'

require 'scout_apm/db_query_metric_set'

module ScoutApm
class DbQueryMetricSetTest < Minitest::Test
  def test_hard_limit
    config = make_fake_config(
      'database_metric_limit' => 5, # The hard limit on db metrics
      'database_metric_report_limit' => 2
    )
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    set = DbQueryMetricSet.new(context)

    set << fake_stat("a", 10)
    set << fake_stat("b", 20)
    set << fake_stat("c", 30)
    set << fake_stat("d", 40)
    set << fake_stat("e", 50)
    set << fake_stat("f", 60)

    assert_equal 5, set.metrics.size
  end

  def test_report_limit
    config = make_fake_config(
      'database_metric_limit' => 50, # much larger max, uninterested in hitting it.
      'database_metric_report_limit' => 2
    )
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    set = DbQueryMetricSet.new(context)
    set << fake_stat("a", 10)
    set << fake_stat("b", 20)
    set << fake_stat("c", 30)
    set << fake_stat("d", 40)
    set << fake_stat("e", 50)
    set << fake_stat("f", 60)

    assert_equal 2, set.metrics_to_report.size
    assert_equal ["f","e"], set.metrics_to_report.map{|m| m.key}
  end

  def test_combine
    config = make_fake_config(
      'database_metric_limit' => 5, # The hard limit on db metrics
      'database_metric_report_limit' => 2
    )
    context = ScoutApm::AgentContext.new().tap{|c| c.config = config }
    set1 = DbQueryMetricSet.new(context)
    set1 << fake_stat("a", 10)
    set1 << fake_stat("b", 20)
    set2 = DbQueryMetricSet.new(context)
    set2 << fake_stat("c", 10)
    set2 << fake_stat("d", 20)

    combined = set1.combine!(set2)
    assert_equal ["a", "b", "c", "d"], combined.metrics.map{|_k, m| m.key}.sort
  end

  def fake_stat(key, call_time)
    OpenStruct.new(
      :key => key,
      :call_time => call_time
    )
  end
end
end
