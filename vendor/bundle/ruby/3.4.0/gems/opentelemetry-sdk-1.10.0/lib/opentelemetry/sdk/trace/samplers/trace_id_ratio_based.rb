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
        # Implements sampling based on a probability.
        class TraceIdRatioBased
          attr_reader :description

          def initialize(probability)
            @probability = probability
            @id_upper_bound = (probability * (2**64 - 1)).ceil
            @description = format('TraceIdRatioBased{%.6f}', probability)
          end

          def ==(other)
            @description == other.description
          end

          # @api private
          #
          # See {Samplers}.
          def should_sample?(trace_id:, parent_context:, links:, name:, kind:, attributes:)
            tracestate = OpenTelemetry::Trace.current_span(parent_context).context.tracestate
            if sample?(trace_id)
              Result.new(decision: Decision::RECORD_AND_SAMPLE, tracestate: tracestate)
            else
              Result.new(decision: Decision::DROP, tracestate: tracestate)
            end
          end

          private

          def sample?(trace_id)
            @probability == 1.0 || trace_id[8, 8].unpack1('Q>') < @id_upper_bound
          end
        end
      end
    end
  end
end
