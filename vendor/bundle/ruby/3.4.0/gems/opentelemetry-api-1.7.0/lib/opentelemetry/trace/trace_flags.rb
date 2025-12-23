# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # TraceFlags contain details about the trace. Unlike Tracestate values,
    # TraceFlags are present in all traces. Currently, the only TraceFlag is a
    # boolean {sampled?} {https://www.w3.org/TR/trace-context/#trace-flags flag}.
    class TraceFlags
      class << self
        private :new

        # Returns a newly created {TraceFlags} with the specified flags.
        #
        # @param [Integer] flags 8-bit byte of bit flags
        # @return [TraceFlags]
        def from_byte(flags)
          flags = 0 unless flags & ~0xFF == 0

          new(flags)
        end
      end

      # @api private
      # The constructor is private and only for use internally by the class.
      # Users should use the {from_byte} factory method to obtain a {TraceFlags}
      # instance.
      #
      # @param [Integer] flags 8-bit byte of bit flags
      # @return [TraceFlags]
      def initialize(flags)
        @flags = flags
      end

      # Returns whether the caller may have recorded trace data. When false,
      # the caller did not record trace data out-of-band.
      #
      # @return [Boolean]
      def sampled?
        (@flags & 1) != 0
      end

      DEFAULT = from_byte(0)
      SAMPLED = from_byte(1)
    end
  end
end
