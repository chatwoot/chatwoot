# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # The Result class represents an arbitrary sampling result. It has
        # boolean values for the sampling decision and whether to record
        # events, and a collection of attributes to be attached to a sampled
        # root span.
        class Result
          EMPTY_HASH = {}.freeze
          DECISIONS = [Decision::RECORD_ONLY, Decision::DROP, Decision::RECORD_AND_SAMPLE].freeze
          private_constant(:EMPTY_HASH, :DECISIONS)

          # Returns a frozen hash of attributes to be attached to the span.
          #
          # @return [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
          attr_reader :attributes

          # Returns a Tracestate to be associated with the span.
          #
          # @return [Tracestate]
          attr_reader :tracestate

          # Returns a new sampling result with the specified decision and
          # attributes.
          #
          # @param [Symbol] decision Whether or not a span should be sampled
          #   and/or record events.
          # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
          #   attributes A frozen or freezable hash containing attributes to be
          #   attached to the span.
          # @param [Tracestate] tracestate A Tracestate that will be associated
          #   with the Span through the new SpanContext. If the sampler returns
          #   an empty Tracestate here, the Tracestate will be cleared, so
          #   samplers SHOULD normally return the passed-in Tracestate if they
          #   do not intend to change it.
          def initialize(decision:, tracestate:, attributes: nil)
            @decision = decision
            @attributes = attributes.freeze || EMPTY_HASH
            @tracestate = tracestate
          end

          # Returns true if this span should be sampled.
          #
          # @return [Boolean] sampling decision
          def sampled?
            @decision == Decision::RECORD_AND_SAMPLE
          end

          # Returns true if this span should record events, attributes, status, etc.
          #
          # @return [Boolean] recording decision
          def recording?
            @decision != Decision::DROP
          end
        end
      end
    end
  end
end
