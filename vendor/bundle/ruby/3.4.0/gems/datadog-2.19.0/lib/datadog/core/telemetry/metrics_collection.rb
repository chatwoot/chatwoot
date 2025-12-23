# frozen_string_literal: true

require_relative 'event'
require_relative 'metric'

module Datadog
  module Core
    module Telemetry
      # MetricsCollection is a thread-safe collection of metrics per namespace
      class MetricsCollection
        attr_reader :namespace, :interval

        def initialize(namespace, aggregation_interval:)
          @namespace = namespace
          @interval = aggregation_interval

          @mutex = Mutex.new

          @metrics = {}
          @distributions = {}
        end

        def inc(metric_name, value, tags: {}, common: true)
          metric = Metric::Count.new(metric_name, tags: tags, common: common)
          fetch_or_add_metric(metric, value)
        end

        def dec(metric_name, value, tags: {}, common: true)
          metric = Metric::Count.new(metric_name, tags: tags, common: common)
          fetch_or_add_metric(metric, -value)
        end

        def gauge(metric_name, value, tags: {}, common: true)
          metric = Metric::Gauge.new(metric_name, tags: tags, common: common, interval: @interval)
          fetch_or_add_metric(metric, value)
        end

        def rate(metric_name, value, tags: {}, common: true)
          metric = Metric::Rate.new(metric_name, tags: tags, common: common, interval: @interval)
          fetch_or_add_metric(metric, value)
        end

        def distribution(metric_name, value, tags: {}, common: true)
          metric = Metric::Distribution.new(metric_name, tags: tags, common: common)
          fetch_or_add_distribution(metric, value)
        end

        def flush!
          @mutex.synchronize do
            events = []
            events << Event::GenerateMetrics.new(@namespace, @metrics.values) if @metrics.any?
            events << Event::Distributions.new(@namespace, @distributions.values) if @distributions.any?

            @metrics = {}
            @distributions = {}

            events
          end
        end

        private

        def fetch_or_add_metric(metric, value)
          @mutex.synchronize do
            m = (@metrics[metric.id] ||= metric)
            m.track(value)
          end
          nil
        end

        def fetch_or_add_distribution(metric, value)
          @mutex.synchronize do
            m = (@distributions[metric.id] ||= metric)
            m.track(value)
          end
          nil
        end
      end
    end
  end
end
