# frozen_string_literal: true

require_relative 'sampler'
require_relative 'rate_sampler'

module Datadog
  module Tracing
    module Sampling
      # Samples at different rates by key.
      class RateByKeySampler < Sampler
        attr_reader \
          :default_key

        def initialize(default_key, default_rate = 1.0, decision: nil, &block)
          super()

          raise ArgumentError, 'No resolver given!' unless block

          @default_key = default_key
          @resolver = block
          @mutex = Mutex.new
          @samplers = {}

          set_rate(default_key, default_rate, decision)
        end

        def resolve(trace)
          @resolver.call(trace)
        end

        def default_sampler
          @samplers[default_key]
        end

        def sample!(trace)
          key = resolve(trace)

          @mutex.synchronize do
            @samplers.fetch(key, default_sampler).sample!(trace)
          end
        end

        def sample_rate(trace)
          key = resolve(trace)

          @mutex.synchronize do
            @samplers.fetch(key, default_sampler).sample_rate
          end
        end

        def update(key, rate, decision: nil)
          @mutex.synchronize do
            set_rate(key, rate, decision)
          end
        end

        def update_all(rate_by_key, decision: nil)
          @mutex.synchronize do
            rate_by_key.each { |key, rate| set_rate(key, rate, decision) }
          end
        end

        def delete(key)
          @mutex.synchronize do
            @samplers.delete(key)
          end
        end

        def delete_if(&block)
          @mutex.synchronize do
            @samplers.delete_if(&block)
          end
        end

        def length
          @samplers.length
        end

        private

        def set_rate(key, rate, decision)
          @samplers[key] = RateSampler.new(rate, decision: decision)
        end
      end
    end
  end
end
