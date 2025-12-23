# frozen_string_literal: true

require_relative '../core/rate_limiter'

module Datadog
  module AppSec
    # Per-thread rate limiter based on token bucket rate limiter.
    #
    # Since AppSec marks sampling to keep on a security event, this limits
    # the flood of egress traces involving AppSec
    class RateLimiter
      THREAD_KEY = :datadog_security_appsec_rate_limiter

      class << self
        def thread_local
          rate_limiter = Thread.current.thread_variable_get(THREAD_KEY)
          return rate_limiter unless rate_limiter.nil?

          Thread.current.thread_variable_set(THREAD_KEY, new(trace_rate_limit))
        end

        # reset a rate limiter: used for testing
        def reset!
          Thread.current.thread_variable_set(THREAD_KEY, nil)
        end

        private

        def trace_rate_limit
          Datadog.configuration.appsec.trace_rate_limit
        end
      end

      def initialize(rate)
        @rate_limiter = Core::TokenBucket.new(rate)
      end

      def limit
        return yield if @rate_limiter.allow?

        Datadog.logger.debug { "Rate limit hit: #{@rate_limiter.current_window_rate} AppSec traces/second" }
      end
    end
  end
end
