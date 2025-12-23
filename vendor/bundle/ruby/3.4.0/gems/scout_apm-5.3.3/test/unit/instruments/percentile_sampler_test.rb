require 'test_helper'

require 'scout_apm/instruments/percentile_sampler'

class PercentileSamplerTest < Minitest::Test
  PercentileSampler = ScoutApm::Instruments::PercentileSampler
  HistogramReport = ScoutApm::Instruments::HistogramReport

  attr_reader :subject

  def setup
    @context = ScoutApm::AgentContext.new
    @subject = PercentileSampler.new(@context)
  end

  def test_initialize_with_logger_and_histogram_set
    assert_equal subject.logger, @context.logger
    assert_equal subject.histograms, @context.request_histograms_by_time
  end

  def test_implements_instrument_interface
    assert subject.respond_to?(:human_name)
  end

  def test_percentiles_returns_one_percentile_per_endpoint_at_time
    histograms[time].add("foo", 10)
    histograms[time].add("bar", 15)
    histograms[time2].add("baz", 15)

    assert_equal subject.percentiles(time).length, 2
    assert_equal subject.percentiles(time2).length, 1
  end

  def test_percentiles_clears_time_from_hash
    histograms[time].add("foo", 10)
    histograms[time2].add("baz", 15)

    subject.percentiles(time)

    assert_false histograms.key?(time)
    assert       histograms.key?(time + 10)
  end

  def test_percentiles_returns_histogram_reports
    histograms[time].add("foo", 10)

    assert subject.percentiles(time).
      all?{ |item| item.is_a?(HistogramReport) }
  end

  def test_percentiles_returns_correct_histogram_report
    histograms[time].add("foo", 100)
    histograms[time].add("foo", 200)
    histograms[time].add("foo", 100)
    histograms[time].add("foo", 300)

    report = subject.percentiles(time).first
    histogram = report.histogram

    assert_equal "foo", report.name
    assert_equal 4, histogram.total
    assert_equal [[2, 100], [1, 200], [1, 300]],
      histogram.bins.map{|bin| [bin.count, bin.value] }
  end

  def test_metrics_saves_histogram_to_store
    store = mock
    store.expects(:track_histograms!)
    subject.metrics(ScoutApm::StoreReportingPeriodTimestamp.new(time), store)
  end


  ################################################################################
  # HistogramReport Test
  ################################################################################
  def test_histogram_report_combine_refuses_to_combine_mismatched_name
    assert_raises { HistogramReport.new("foo", histogram).combine!(HistogramReport.new("bar", histogram)) }
  end

  def test_histogram_report_merge_keeps_name
    report1 = HistogramReport.new("foo", histogram)
    report2 = HistogramReport.new("foo", histogram)
    combined = report1.combine!(report2)

    assert "foo", combined.name
  end

  def test_histogram_report_combine_merges_histograms
    histogram1 = histogram
    histogram2 = histogram
    histogram1.add(1)
    histogram1.add(2)
    histogram2.add(2)
    histogram2.add(3)

    report1 = HistogramReport.new("foo", histogram1)
    report2 = HistogramReport.new("foo", histogram2)
    combined = report1.combine!(report2)

    assert_equal 4, combined.histogram.total
    assert_equal [[1, 1], [2, 2], [1, 3]],
      combined.histogram.bins.map{|bin| [bin.count, bin.value.to_i] }
  end

  ################################################################################
  # Test Helpers
  ################################################################################
  def logger
    @logger ||= begin
                  @logger_io = StringIO.new
                  Logger.new(@logger_io)
                end
  end

  def histograms
    @context.request_histograms_by_time
  end

  def histogram
    max_bins = 20
    ScoutApm::NumericHistogram.new(max_bins)
  end

  # An arbitrary time
  def time
    @time ||= Time.now
  end

  def time2
    time + 10
  end
end

