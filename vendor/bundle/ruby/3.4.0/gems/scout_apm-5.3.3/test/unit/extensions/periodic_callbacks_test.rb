require 'test_helper'

class PeriodicCallbacksTest < Minitest::Test

  # We don't have a test that ensures we actually report data to the server, so we can't be 100% sure this doesn't break
  # reporting.
  def test_broken_callback_does_not_throw_exception
    ScoutApm::Extensions::Config.add_periodic_callback(BrokenCallback.new)
    # Runs via agent context as calling +add_periodic_callback+ initializing the context + extension config.
    ScoutApm::Agent.instance.context.extensions.run_periodic_callbacks(reporting_period,metadata)
  end

  def test_callback_runs
    Thread.current[:periodic_callback_output] = nil
    ScoutApm::Extensions::Config.add_periodic_callback(PeriodicCallback.new)
    ScoutApm::Agent.instance.context.extensions.run_periodic_callbacks(reporting_period,metadata)
    assert Thread.current[:periodic_callback_output]
  end

  def run_proc_callback
    Thread.current[:proc_periodic] = nil
    ScoutApm::Extensions::Config.add_periodic_callback(Proc.new { |reporting_period, metadata| Thread.current[:proc_periodic] = Time.at(metadata[:agent_time].to_i) })
    ScoutApm::Agent.instance.context.extensions.run_periodic_callbacks(reporting_period,metadata)
    assert Thread.current[:proc_periodic]
  end

  # Doesn't respond to +call+.
  class BrokenCallback
  end

  # Sets a Thread local so we can verify that the callback ran.
  class PeriodicCallback
    def call(reporting_period,metadata)
      Thread.current[:periodic_callback_output] = true
    end
  end

  private

  def reporting_period
    rp = ScoutApm::StoreReportingPeriod.new(Time.at(metadata[:agent_time].to_i), ScoutApm::AgentContext.new)
    rp.absorb_metrics!(metrics)
  end

  def metrics
    meta = ScoutApm::MetricMeta.new("Controller/users/index")
    stats = ScoutApm::MetricStats.new
    stats.update!(0.1)
    {
      meta => stats
    }
  end

  def metadata
    {:app_root=>"/srv/rails_app", :unique_id=>"ID", :agent_version=>"2.4.10", :agent_time=>"1523287920", :agent_pid=>21581, :platform=>"ruby"}
  end

end
