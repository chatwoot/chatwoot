# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # SpanExporter describes a duck type. It is not required to subclass this
        # class to provide an implementation of SpanExporter, provided the interface is
        # satisfied. SpanExporter allows different tracing services to export
        # recorded data for sampled spans in their own format.
        #
        # To export data an exporter MUST be registered to the {TracerProvider} using
        # a {SpanProcessor} implementation.
        class SpanExporter
          def initialize
            @stopped = false
          end

          # Called to export sampled {SpanData}s.
          #
          # @param [Enumerable<SpanData>] span_data the list of sampled {SpanData} to be
          #   exported.
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] the result of the export.
          def export(span_data, timeout: nil)
            return SUCCESS unless @stopped

            FAILURE
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
          def shutdown(timeout: nil)
            @stopped = true
            SUCCESS
          end
        end
      end
    end
  end
end
