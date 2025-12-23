# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Samplers
        # @api private
        #
        # Implements a sampler returning a result with a constant decision.
        class ConstantSampler
          attr_reader :description

          def initialize(decision:, description:)
            @decision = decision
            @description = description
          end

          def ==(other)
            @decision == other.decision && @description == other.description
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            Result.new(decision: @decision, tracestate: OpenTelemetry::Trace.current_span(parent_context).context.tracestate)
          end

          protected

          attr_reader :decision
        end
      end
    end
  end
end
