# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # A SpanContext contains the state that must propagate to child {Span}s and across process boundaries.
    # It contains the identifiers (a trace ID and span ID) associated with the {Span}, a set of
    # {TraceFlags}, a system-specific tracestate, and a boolean indicating that the SpanContext was
    # extracted from the wire.
    class SpanContext
      attr_reader :trace_flags, :tracestate

      # Returns a new {SpanContext}.
      #
      # @param [optional String] trace_id The trace ID associated with a {Span}.
      # @param [optional String] span_id The span ID associated with a {Span}.
      # @param [optional TraceFlags] trace_flags The trace flags associated with a {Span}.
      # @param [optional Tracestate] tracestate The tracestate associated with a {Span}. May be nil.
      # @param [optional Boolean] remote Whether the {SpanContext} was extracted from the wire.
      # @return [SpanContext]
      def initialize(
        trace_id: Trace.generate_trace_id,
        span_id: Trace.generate_span_id,
        trace_flags: TraceFlags::DEFAULT,
        tracestate: Tracestate::DEFAULT,
        remote: false
      )
        @trace_id = trace_id
        @span_id = span_id
        @trace_flags = trace_flags
        @tracestate = tracestate
        @remote = remote
      end

      # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) trace ID.
      #
      # @return [String] A 32-hex-character lowercase string.
      def hex_trace_id
        @trace_id.unpack1('H*')
      end

      # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) span ID.
      #
      # @return [String] A 16-hex-character lowercase string.
      def hex_span_id
        @span_id.unpack1('H*')
      end

      # Returns the binary representation of the trace ID.
      #
      # @return [String] A 16-byte binary string.
      attr_reader :trace_id

      # Returns the binary representation of the span ID.
      #
      # @return [String] An 8-byte binary string.
      attr_reader :span_id

      # Returns true if the {SpanContext} has a non-zero trace ID and non-zero span ID.
      #
      # @return [Boolean]
      def valid?
        @trace_id != INVALID_TRACE_ID && @span_id != INVALID_SPAN_ID
      end

      # Returns true if the {SpanContext} was propagated from a remote parent.
      #
      # @return [Boolean]
      def remote?
        @remote
      end

      # Represents an invalid {SpanContext}, with an invalid trace ID and an invalid span ID.
      INVALID = new(trace_id: INVALID_TRACE_ID, span_id: INVALID_SPAN_ID)
    end
  end
end
