# frozen_string_literal: true

require 'zlib'
require_relative 'lru_cache'
require_relative 'route_extractor'
require_relative '../../core/utils/time'

module Datadog
  module AppSec
    module APISecurity
      # A thread-local sampler for API security based on defined delay between
      # samples with caching capability.
      class Sampler
        THREAD_KEY = :datadog_appsec_api_security_sampler
        MAX_CACHE_SIZE = 4096

        class << self
          def thread_local
            sampler = Thread.current.thread_variable_get(THREAD_KEY)
            return sampler unless sampler.nil?

            Thread.current.thread_variable_set(THREAD_KEY, new(sample_delay))
          end

          # @api private
          def reset!
            Thread.current.thread_variable_set(THREAD_KEY, nil)
          end

          private

          def sample_delay
            Datadog.configuration.appsec.api_security.sample_delay
          end
        end

        def initialize(sample_delay)
          raise ArgumentError, 'sample_delay must be an Integer' unless sample_delay.is_a?(Integer)

          @cache = LRUCache.new(MAX_CACHE_SIZE)
          @sample_delay_seconds = sample_delay
        end

        def sample?(request, response)
          return true if @sample_delay_seconds.zero?

          key = Zlib.crc32("#{request.request_method}#{RouteExtractor.route_pattern(request)}#{response.status}")
          current_timestamp = Core::Utils::Time.now.to_i
          cached_timestamp = @cache[key] || 0

          return false if current_timestamp - cached_timestamp <= @sample_delay_seconds

          @cache.store(key, current_timestamp)
          true
        end
      end
    end
  end
end
