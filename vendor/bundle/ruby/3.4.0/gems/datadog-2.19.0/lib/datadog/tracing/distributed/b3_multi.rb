# frozen_string_literal: true

require_relative 'helpers'
require_relative '../trace_digest'
require_relative '../utils'

module Datadog
  module Tracing
    module Distributed
      # B3 multi header-style trace propagation.
      # @see https://github.com/openzipkin/b3-propagation#multiple-headers
      class B3Multi
        B3_TRACE_ID_KEY = 'x-b3-traceid'
        B3_SPAN_ID_KEY = 'x-b3-spanid'
        B3_SAMPLED_KEY = 'x-b3-sampled'

        def initialize(
          fetcher:,
          trace_id_key: B3_TRACE_ID_KEY,
          span_id_key: B3_SPAN_ID_KEY,
          sampled_key: B3_SAMPLED_KEY
        )
          @trace_id_key = trace_id_key
          @span_id_key = span_id_key
          @sampled_key = sampled_key
          @fetcher = fetcher
        end

        def inject!(digest, data = {})
          return if digest.nil?

          # DEV: We need these to be hex encoded
          data[@trace_id_key] = format('%032x', digest.trace_id)
          data[@span_id_key] = format('%016x', digest.span_id || 0) # # Fall back to zero (invalid) if not present

          if digest.trace_sampling_priority
            sampling_priority = Helpers.clamp_sampling_priority(
              digest.trace_sampling_priority
            )
            data[@sampled_key] = sampling_priority.to_s
          end

          data
        end

        def extract(data)
          # DEV: B3 doesn't have "origin"
          fetcher = @fetcher.new(data)

          trace_id = Helpers.parse_hex_id(fetcher[@trace_id_key])

          # Return early if this propagation is not valid
          return if trace_id.nil? || trace_id <= 0 || trace_id > Tracing::Utils::TraceId::MAX

          span_id = Helpers.parse_hex_id(fetcher[@span_id_key])

          # Return early if this propagation is not valid
          return if span_id.nil? || span_id <= 0 || span_id > Tracing::Utils::EXTERNAL_MAX_ID

          # We don't need to try and convert sampled since B3 supports 0/1 (AUTO_REJECT/AUTO_KEEP)
          sampling_priority = Helpers.parse_decimal_id(fetcher[@sampled_key])

          TraceDigest.new(
            trace_id: trace_id,
            span_id: span_id,
            trace_sampling_priority: sampling_priority,
            span_remote: true,
          )
        end
      end
    end
  end
end
