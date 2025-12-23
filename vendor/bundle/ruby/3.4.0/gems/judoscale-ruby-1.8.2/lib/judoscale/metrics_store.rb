# frozen_string_literal: true

require "singleton"
require "judoscale/metric"
require "judoscale/report"

module Judoscale
  class MetricsStore
    include Singleton

    attr_reader :metrics, :flushed_at

    def initialize
      @metrics = []
      @flushed_at = Time.now
    end

    def push(identifier, value, time = Time.now, queue_name = nil)
      # If it's been two minutes since clearing out the store, stop collecting metrics.
      # There could be an issue with the reporter, and continuing to collect will consume linear memory.
      return if @flushed_at && @flushed_at < Time.now - 120

      @metrics << Metric.new(identifier, value, time, queue_name)
    end

    def flush
      @flushed_at = Time.now
      flushed_metrics = []

      while (metric = @metrics.shift)
        flushed_metrics << metric
      end

      flushed_metrics
    end

    def clear
      @metrics.clear
    end
  end
end
