# frozen_string_literal: true

require_relative 'helpers'
require_relative '../trace_digest'

module Datadog
  module Tracing
    module Distributed
      # B3 single header-style trace propagation.
      #
      # DEV: Format:
      # DEV:   b3: {TraceId}-{SpanId}-{SamplingState}-{ParentSpanId}
      # DEV: https://github.com/apache/incubator-zipkin-b3-propagation/tree/7c6e9f14d6627832bd80baa87ac7dabee7be23cf#single-header
      # DEV: `{SamplingState}` and `{ParentSpanId}` are optional
      #
      # @see https://github.com/openzipkin/b3-propagation#single-header
      class B3Single
        B3_SINGLE_HEADER_KEY = 'b3'

        def initialize(fetcher:, key: B3_SINGLE_HEADER_KEY)
          @key = key
          @fetcher = fetcher
        end

        def inject!(digest, env)
          return if digest.nil?

          span_id = digest.span_id || 0 # Fall back to zero (invalid) if not present

          # DEV: We need these to be hex encoded
          value = "#{format('%032x', digest.trace_id)}-#{format('%016x', span_id)}"

          if digest.trace_sampling_priority
            sampling_priority = Helpers.clamp_sampling_priority(
              digest.trace_sampling_priority
            )
            value += "-#{sampling_priority}"
          end

          env[@key] = value
          env
        end

        def extract(env)
          fetcher = @fetcher.new(env)
          value = fetcher[@key]

          return unless value

          parts = value.split('-')
          trace_id = Helpers.parse_hex_id(parts[0]) unless parts.empty?
          # Return early if this propagation is not valid
          return if trace_id.nil? || trace_id <= 0 || trace_id > Tracing::Utils::TraceId::MAX

          span_id = Helpers.parse_hex_id(parts[1]) if parts.length > 1
          # Return early if this propagation is not valid
          return if span_id.nil? || span_id <= 0 || span_id > Tracing::Utils::EXTERNAL_MAX_ID

          sampling_priority = Helpers.parse_decimal_id(parts[2]) if parts.length > 2

          TraceDigest.new(
            span_id: span_id,
            trace_id: trace_id,
            trace_sampling_priority: sampling_priority,
            span_remote: true,
          )
        end
      end
    end
  end
end
