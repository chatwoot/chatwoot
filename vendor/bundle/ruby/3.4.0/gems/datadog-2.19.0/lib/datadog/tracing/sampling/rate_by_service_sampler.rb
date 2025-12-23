# frozen_string_literal: true

require_relative 'rate_by_key_sampler'

module Datadog
  module Tracing
    module Sampling
      # {Datadog::Tracing::Sampling::RateByServiceSampler} samples different services at different rates
      class RateByServiceSampler < RateByKeySampler
        DEFAULT_KEY = 'service:,env:'

        def initialize(default_rate = 1.0, env: nil, decision: Datadog::Tracing::Sampling::Ext::Decision::DEFAULT)
          super(
            DEFAULT_KEY,
            default_rate,
            decision: decision,
            &method(:key_for)
          )

          @env = env
        end

        def update(rate_by_service, decision: nil)
          # Remove any old services
          delete_if { |key, _| key != DEFAULT_KEY && !rate_by_service.key?(key) }

          # Update each service rate
          update_all(rate_by_service, decision: decision)

          # Emit metric for service cache size
          Datadog.health_metrics.sampling_service_cache_length(length)
        end

        private

        # DEV: Creating a string on every trace to perform a single Hash lookup is expensive.
        #
        # Using 2 nested hashes: 1 for env and 1 for service is the fastest option.
        # This approach requires large API changes to `RateByKeySampler`.
        #
        # Reducing the interpolated string size, by using a 1 character separator,
        # is also measurably faster than the current method. This approach does not
        # require changes to `RateByKeySampler`.
        #
        # Keep in mind that these changes also require changes to `#update`.
        #
        # Comparison:
        #  2 nested hashes: `service_hash.fetch(service, {}).fetch(env, default_rate)`
        #                   7730045 i/s
        # 1 char separator: `hash.fetch("#{service}\0#{env}", default_rate)`
        #                   4302801 i/s - 1.80x slower
        #          current: `hash.fetch("service:#{service},env:#{env}", default_rate)`
        #                   2720459 i/s - 2.84x slower
        def key_for(trace)
          # Resolve env dynamically, if Proc is given.
          env = @env.is_a?(Proc) ? @env.call : @env

          "service:#{trace.service},env:#{env}"
        end
      end
    end
  end
end
