# frozen_string_literal: true

require_relative 'utils/time'

module Datadog
  module Core
    # Checks for rate limiting on a resource.
    class RateLimiter
      # Checks if resource of specified size can be
      # conforms with the current limit.
      #
      # Implementations of this method are not guaranteed
      # to be side-effect free.
      #
      # @return [Boolean] whether a resource conforms with the current limit
      def allow?(size = 1)
      end

      # The effective rate limiting ratio based on
      # recent calls to `allow?`.
      #
      # @return [Float] recent allowance ratio
      def effective_rate
      end
    end

    # Implementation of the Token Bucket metering algorithm
    # for rate limiting.
    #
    # @see https://en.wikipedia.org/wiki/Token_bucket Token bucket
    class TokenBucket < RateLimiter
      attr_reader :rate, :max_tokens

      # @param rate [Numeric] Allowance rate, in units per second
      #  if rate is negative, always allow
      #  if rate is zero, never allow
      # @param max_tokens [Numeric] Limit of available tokens
      def initialize(rate, max_tokens = rate)
        super()

        raise ArgumentError, "rate must be a number: #{rate}" unless rate.is_a?(Numeric)
        raise ArgumentError, "max_tokens must be a number: #{max_tokens}" unless max_tokens.is_a?(Numeric)

        @rate = rate
        @max_tokens = max_tokens

        @tokens = max_tokens
        @total_messages = 0
        @conforming_messages = 0
        @prev_conforming_messages = nil
        @prev_total_messages = nil
        @current_window = nil

        @last_refill = Core::Utils::Time.get_time
      end

      # Checks if a message of provided +size+
      # conforms with the current bucket limit.
      #
      # If it does, return +true+ and remove +size+
      # tokens from the bucket.
      # If it does not, return +false+ without affecting
      # the tokens from the bucket.
      #
      # @return [Boolean] +true+ if message conforms with current bucket limit
      def allow?(size = 1)
        allowed = should_allow?(size)
        update_rate_counts(allowed)
        allowed
      end

      # Ratio of 'conformance' per 'total messages' checked
      # averaged for the past 2 buckets
      #
      # Returns +1.0+ when no messages have been checked yet.
      #
      # @return [Float] Conformance ratio, between +[0,1]+
      def effective_rate
        return 0.0 if @rate.zero?
        return 1.0 if @rate < 0 || @total_messages.zero?

        return current_window_rate if @prev_conforming_messages.nil? || @prev_total_messages.nil?

        (@conforming_messages.to_f + @prev_conforming_messages.to_f) / (@total_messages + @prev_total_messages)
      end

      # Ratio of 'conformance' per 'total messages' checked
      # on this bucket
      #
      # Returns +1.0+ when no messages have been checked yet.
      #
      # @return [Float] Conformance ratio, between +[0,1]+
      def current_window_rate
        return 1.0 if @total_messages.zero?

        @conforming_messages.to_f / @total_messages
      end

      # @return [Numeric] number of tokens currently available
      def available_tokens
        @tokens
      end

      private

      def refill_since_last_message
        now = Core::Utils::Time.get_time
        elapsed = now - @last_refill

        # Update the number of available tokens, but ensure we do not exceed the max
        # we return the min of tokens + rate*elapsed, or max tokens
        refill_tokens(@rate * elapsed)

        @last_refill = now
      end

      def refill_tokens(size)
        @tokens += size
        @tokens = @max_tokens if @tokens > @max_tokens
      end

      def increment_total_count
        @total_messages += 1
      end

      def increment_conforming_count
        @conforming_messages += 1
      end

      def should_allow?(size = 1)
        # rate limit of 0 blocks everything
        return false if @rate.zero?

        # negative rate limit disables rate limiting
        return true if @rate < 0

        refill_since_last_message

        # if tokens < 1 we don't allow?
        return false if @tokens < size

        @tokens -= size

        true
      end

      # Sets and Updates the past two 1 second windows for which
      # the rate limiter must compute it's rate over and updates
      # the total count, and conforming message count if +allowed+
      def update_rate_counts(allowed)
        now = Core::Utils::Time.get_time

        # No tokens have been seen yet, start a new window
        if @current_window.nil?
          @current_window = now
        # If more than 1 second has past since last window, reset
        elsif now - @current_window >= 1
          @prev_conforming_messages = @conforming_messages
          @prev_total_messages = @total_messages
          @conforming_messages = 0
          @total_messages = 0
          @current_window = now
        end

        increment_conforming_count if allowed

        increment_total_count
      end
    end

    # {Datadog::Core::RateLimiter} that accepts all resources,
    # with no limits.
    class UnlimitedLimiter < RateLimiter
      # @return [Boolean] always +true+
      def allow?(_ = 1)
        true
      end

      # @return [Float] always 100%
      def effective_rate
        1.0
      end
    end
  end
end
