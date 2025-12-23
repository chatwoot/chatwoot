# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # A SpanExporter implementation that can be used to test OpenTelemetry integration.
        #
        # @example Usage in a test suite:
        #   class MyClassTest
        #     def setup
        #       @tracer_provider = TracerProvider.new
        #       # The default is `recording: true`, which is appropriate in non-test environments.
        #       @exporter = InMemorySpanExporter.new(recording: false)
        #       @tracer_provider.add_span_processor(SimpleSampledSpansProcessor.new(@exporter))
        #     end
        #
        #     def test_finished_spans
        #       @exporter.recording = true
        #       @tracer_provider.tracer.in_span("span") {}
        #
        #       spans = @exporter.finished_spans
        #       spans.wont_be_nil
        #       spans.size.must_equal(1)
        #       spans[0].name.must_equal("span")
        #
        #       @exporter.recording = false
        #     end
        #   end
        class InMemorySpanExporter
          # Controls whether or not the exporter will record spans, or discard them.
          # @return [Boolean] when true, the exporter is recording. By default, this is true.
          attr_accessor :recording

          # Returns a new instance of the {InMemorySpanExporter}.
          #
          # @return a new instance of the {InMemorySpanExporter}.
          def initialize(recording: true)
            @finished_spans = []
            @stopped = false
            @recording = recording
            @mutex = Mutex.new
          end

          # Returns a frozen array of the finished {SpanData}s, represented by
          # {io.opentelemetry.proto.trace.v1.Span}.
          #
          # @return [Array<SpanData>] a frozen array of the finished {SpanData}s.
          def finished_spans
            @mutex.synchronize do
              @finished_spans.clone.freeze
            end
          end

          # Clears the internal collection of finished {Span}s.
          #
          # Does not reset the state of this exporter if already shutdown.
          def reset
            @mutex.synchronize do
              @finished_spans.clear
            end
          end

          # Called to export sampled {SpanData}s.
          #
          # @param [Enumerable<SpanData>] span_datas the list of sampled {SpanData}s to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export, SUCCESS or
          #   FAILURE
          def export(span_datas, timeout: nil)
            @mutex.synchronize do
              return FAILURE if @stopped

              @finished_spans.concat(span_datas.to_a) if @recording
            end
            SUCCESS
          end

          # Called when {TracerProvider#force_flush} is called, if this exporter is
          # registered to a {TracerProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            SUCCESS
          end

          # Called when {TracerProvider#shutdown} is called, if this exporter is
          # registered to a {TracerProvider} object.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            @mutex.synchronize do
              @finished_spans.clear
              @stopped = true
            end
            SUCCESS
          end
        end
      end
    end
  end
end
