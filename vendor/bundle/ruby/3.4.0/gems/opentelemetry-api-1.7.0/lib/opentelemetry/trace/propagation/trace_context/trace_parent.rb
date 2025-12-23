# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0
module OpenTelemetry
  module Trace
    module Propagation
      module TraceContext
        # A TraceParent is an implementation of the W3C trace context specification
        # https://www.w3.org/TR/trace-context/
        # {Trace::SpanContext}
        class TraceParent
          InvalidFormatError = Class.new(Error)
          InvalidVersionError = Class.new(Error)
          InvalidTraceIDError = Class.new(Error)
          InvalidSpanIDError = Class.new(Error)

          TRACE_PARENT_HEADER = 'traceparent'
          SUPPORTED_VERSION = 0
          private_constant :SUPPORTED_VERSION
          MAX_VERSION = 254
          private_constant :MAX_VERSION

          REGEXP = /^(?<version>[A-Fa-f0-9]{2})-(?<trace_id>[A-Fa-f0-9]{32})-(?<span_id>[A-Fa-f0-9]{16})-(?<flags>[A-Fa-f0-9]{2})(?<ignored>-.*)?$/
          private_constant :REGEXP

          INVALID_TRACE_ID = OpenTelemetry::Trace::SpanContext::INVALID.hex_trace_id
          INVALID_SPAN_ID = OpenTelemetry::Trace::SpanContext::INVALID.hex_span_id
          private_constant :INVALID_TRACE_ID, :INVALID_SPAN_ID

          class << self
            # Creates a new {TraceParent} from a supplied {Trace::SpanContext}
            # @param [SpanContext] ctx The span context
            # @return [TraceParent] a trace parent
            def from_span_context(ctx)
              new(trace_id: ctx.trace_id, span_id: ctx.span_id, flags: ctx.trace_flags)
            end

            # Deserializes the {TraceParent} from the string representation
            # @param [String] string The serialized trace parent
            # @return [TraceParent] a trace_parent
            # @raise [InvalidFormatError] on an invalid format
            # @raise [InvalidVerionError] on an invalid version
            # @raise [InvalidTraceIDError] on an invalid trace_id
            # @raise [InvalidSpanIDError] on an invalid span_id
            def from_string(string)
              matches = match_input(string)

              version = parse_version(matches[:version])
              raise InvalidFormatError if version > SUPPORTED_VERSION && string.length < 55

              trace_id = parse_trace_id(matches[:trace_id])
              span_id = parse_span_id(matches[:span_id])
              flags = parse_flags(matches[:flags])

              new(trace_id: trace_id, span_id: span_id, flags: flags)
            end

            private

            def match_input(string)
              matches = REGEXP.match(string)
              raise InvalidFormatError, 'regexp match failed' if !matches || matches.length < 6

              matches
            end

            def parse_version(string)
              v = string.to_i(16)
              raise InvalidFormatError, string unless v
              raise InvalidVersionError, v if v > MAX_VERSION

              v
            end

            def parse_trace_id(string)
              raise InvalidTraceIDError, string if string == INVALID_TRACE_ID

              string.downcase!
              Array(string).pack('H*')
            end

            def parse_span_id(string)
              raise InvalidSpanIDError, string if string == INVALID_SPAN_ID

              string.downcase!
              Array(string).pack('H*')
            end

            def parse_flags(string)
              OpenTelemetry::Trace::TraceFlags.from_byte(string.to_i(16))
            end
          end

          attr_reader :version, :trace_id, :span_id, :flags

          private_class_method :new

          # Returns the sampling choice from the trace_flags
          # @return [Boolean] the sampling choice
          def sampled?
            flags.sampled?
          end

          # converts this object into a string according to the w3c spec
          # @return [String] the serialized trace_parent
          def to_s
            "00-#{trace_id.unpack1('H*')}-#{span_id.unpack1('H*')}-#{flag_string}"
          end

          private

          def flag_string
            # the w3c standard only dictates the one flag for this version
            # therefore we can only output the one flag.
            flags.sampled? ? '01' : '00'
          end

          def initialize(trace_id: nil, span_id: nil, version: SUPPORTED_VERSION, flags: Trace::TraceFlags::DEFAULT)
            @trace_id = trace_id
            @span_id = span_id
            @version = version
            @flags = flags
          end
        end
      end
    end
  end
end
