# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # The Export module contains the built-in exporters and span processors for the OpenTelemetry
      # reference implementation.
      module Export
        # Raised when an export fails; spans are available via :spans accessor
        class ExportError < OpenTelemetry::Error
          # Returns the {Span} array for this exception
          #
          # @return [Array<OpenTelemetry::SDK::Trace::Span>]
          attr_reader :spans

          # @param [Array<OpenTelemetry::SDK::Trace::Span>] spans the array of spans that failed to export
          def initialize(spans)
            super("Unable to export #{spans.size} spans")
            @spans = spans
          end
        end

        # Result codes for the SpanExporter#export method and the SpanProcessor#force_flush and SpanProcessor#shutdown methods.

        # The operation finished successfully.
        SUCCESS = 0

        # The operation finished with an error.
        FAILURE = 1

        # Additional result code for the SpanProcessor#force_flush and SpanProcessor#shutdown methods.

        # The operation timed out.
        TIMEOUT = 2
      end
    end
  end
end

require 'opentelemetry/sdk/trace/export/batch_span_processor'
require 'opentelemetry/sdk/trace/export/console_span_exporter'
require 'opentelemetry/sdk/trace/export/in_memory_span_exporter'
require 'opentelemetry/sdk/trace/export/metrics_reporter'
require 'opentelemetry/sdk/trace/export/span_exporter'
require 'opentelemetry/sdk/trace/export/simple_span_processor'
