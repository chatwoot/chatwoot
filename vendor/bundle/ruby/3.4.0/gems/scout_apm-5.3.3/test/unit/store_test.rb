require 'test_helper'

require 'scout_apm/store'

class FakeFailingLayaway
  attr_reader :rps_written
  def write_reporting_period(rp)
    @rps_written ||= []
    @rps_written << rp
  end
end

class StoreTest < Minitest::Test
  # TODO: Introduce a clock object to avoid having to use 'force'
  def test_writing_layaway_removes_timestamps
    s = ScoutApm::Store.new(ScoutApm::AgentContext.new)
    s.track_one!("Controller", "user/show", 10)

    assert_equal(1, s.instance_variable_get('@reporting_periods').size)

    s.write_to_layaway(FakeFailingLayaway.new, true)

    assert_equal({}, s.instance_variable_get('@reporting_periods'))
  end

  def test_writing_layaway_removes_stale_timestamps
    context = ScoutApm::AgentContext.new
    current_time = Time.now.utc
    current_rp = ScoutApm::StoreReportingPeriod.new(current_time, context)
    stale_rp = ScoutApm::StoreReportingPeriod.new(current_time - current_time.sec - 120, context)

    s = ScoutApm::Store.new(context)
    ScoutApm::Instruments::Process::ProcessMemory.new(context).metrics(stale_rp.timestamp, s)
    ScoutApm::Instruments::Process::ProcessMemory.new(context).metrics(current_rp.timestamp, s)
    assert_equal 2, s.instance_variable_get('@reporting_periods').size

    s.write_to_layaway(FakeFailingLayaway.new, true)

    assert_equal({}, s.instance_variable_get('@reporting_periods'))
  end
end

class StoreReportingPeriodTest < Minitest::Test
  HistogramReport = ScoutApm::Instruments::HistogramReport

  attr_reader :subject

  def setup
    @subject = ScoutApm::StoreReportingPeriod.new(ScoutApm::StoreReportingPeriodTimestamp.new(Time.now), ScoutApm::AgentContext.new)
  end

  # Check default values at creation time
  def test_empty_values
    assert_equal [], subject.histograms
    assert_equal ScoutApm::ScoredItemSet.new, subject.request_traces
    assert_equal ScoutApm::ScoredItemSet.new, subject.job_traces
    assert_equal ScoutApm::MetricSet.new, subject.metric_set
  end

  def test_merge_histograms
    histogramFoo1 = histogram
    histogramFoo2 = histogram
    histogramBar1 = histogram
    histogramBar2 = histogram

    # This assertion may be fragile to reordering in the merge_histograms! function.
    histogramFoo1.expects(:combine!).with(histogramFoo2)
    histogramBar1.expects(:combine!).with(histogramBar2)

    subject.merge_histograms!([
      HistogramReport.new("foo", histogramFoo1),
      HistogramReport.new("bar", histogramBar1),
    ])

    subject.merge_histograms!([
      HistogramReport.new("foo", histogramFoo2),
      HistogramReport.new("bar", histogramBar2),
    ])

    result = subject.histograms
    assert_equal 2, result.length
    assert_equal ["bar", "foo"], result.map(&:name).sort
  end

  ###############################################################################
  # Helpers
  ###############################################################################
  def histogram
    max_bins = 20
    ScoutApm::NumericHistogram.new(max_bins)
  end
end
