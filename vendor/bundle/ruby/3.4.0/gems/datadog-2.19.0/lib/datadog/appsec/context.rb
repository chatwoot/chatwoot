# frozen_string_literal: true

require_relative 'metrics'

module Datadog
  module AppSec
    # This class accumulates the context over the request life-cycle and exposes
    # interface sufficient for instrumentation to perform threat detection.
    class Context
      ActiveContextError = Class.new(StandardError)

      # TODO: add delegators for active trace span
      attr_reader :trace, :span, :events

      class << self
        def activate(context)
          raise ArgumentError, 'not a Datadog::AppSec::Context' unless context.instance_of?(Context)
          raise ActiveContextError, 'another context is active, nested contexts are not supported' if active

          Thread.current[Ext::ACTIVE_CONTEXT_KEY] = context
        end

        def deactivate
          active&.finalize!
        ensure
          Thread.current[Ext::ACTIVE_CONTEXT_KEY] = nil
        end

        def active
          Thread.current[Ext::ACTIVE_CONTEXT_KEY]
        end
      end

      def initialize(trace, span, waf_runner)
        @trace = trace
        @span = span
        @events = []
        @waf_runner = waf_runner
        @metrics = Metrics::Collector.new
      end

      def run_waf(persistent_data, ephemeral_data, timeout = WAF::LibDDWAF::DDWAF_RUN_TIMEOUT)
        result = @waf_runner.run(persistent_data, ephemeral_data, timeout)

        @metrics.record_waf(result)
        result
      end

      def run_rasp(type, persistent_data, ephemeral_data, timeout = WAF::LibDDWAF::DDWAF_RUN_TIMEOUT)
        result = @waf_runner.run(persistent_data, ephemeral_data, timeout)

        Metrics::Telemetry.report_rasp(type, result)
        @metrics.record_rasp(result)

        result
      end

      def extract_schema
        @waf_runner.run({'waf.context.processor' => {'extract-schema' => true}}, {})
      end

      def export_metrics
        return if @span.nil?

        Metrics::Exporter.export_waf_metrics(@metrics.waf, @span)
        Metrics::Exporter.export_rasp_metrics(@metrics.rasp, @span)
      end

      def finalize!
        @waf_runner.finalize!
      end
    end
  end
end
