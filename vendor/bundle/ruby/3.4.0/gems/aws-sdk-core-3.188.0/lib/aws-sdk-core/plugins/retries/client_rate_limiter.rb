# frozen_string_literal: true

module Aws
  module Plugins
    module Retries
      # @api private
      # Used only in 'adaptive' retry mode
      class ClientRateLimiter
        MIN_CAPACITY = 1
        MIN_FILL_RATE = 0.5
        SMOOTH = 0.8
        # How much to scale back after a throttling response
        BETA = 0.7
        # Controls how aggressively we scale up after being throttled
        SCALE_CONSTANT = 0.4

        def initialize
          @mutex                = Mutex.new
          @fill_rate            = nil
          @max_capacity         = nil
          @current_capacity     = 0
          @last_timestamp       = nil
          @enabled              = false
          @measured_tx_rate     = 0
          @last_tx_rate_bucket  = Aws::Util.monotonic_seconds
          @request_count        = 0
          @last_max_rate        = 0
          @last_throttle_time   = Aws::Util.monotonic_seconds
          @calculated_rate      = nil
        end

        def token_bucket_acquire(amount, wait_to_fill = true)
          # Client side throttling is not enabled until we see a
          # throttling error
          return unless @enabled

          @mutex.synchronize do
            token_bucket_refill

            # Next see if we have enough capacity for the requested amount
            while @current_capacity < amount
              raise Aws::Errors::RetryCapacityNotAvailableError unless wait_to_fill
              @mutex.sleep((amount - @current_capacity) / @fill_rate)
              token_bucket_refill
            end
            @current_capacity -= amount
          end
        end

        def update_sending_rate(is_throttling_error)
          @mutex.synchronize do
            update_measured_rate

            if is_throttling_error
              rate_to_use = if @enabled
                              [@measured_tx_rate, @fill_rate].min
                            else
                              @measured_tx_rate
                            end

              # The fill_rate is from the token bucket
              @last_max_rate = rate_to_use
              calculate_time_window
              @last_throttle_time = Aws::Util.monotonic_seconds
              @calculated_rate = cubic_throttle(rate_to_use)
              enable_token_bucket
            else
              calculate_time_window
              @calculated_rate = cubic_success(Aws::Util.monotonic_seconds)
            end

            new_rate = [@calculated_rate, 2 * @measured_tx_rate].min
            token_bucket_update_rate(new_rate)
          end
        end

        private

        def token_bucket_refill
          timestamp = Aws::Util.monotonic_seconds
          unless @last_timestamp
            @last_timestamp = timestamp
            return
          end

          fill_amount = (timestamp - @last_timestamp) * @fill_rate
          @current_capacity = [
            @max_capacity, @current_capacity + fill_amount
          ].min

          @last_timestamp = timestamp
        end

        def token_bucket_update_rate(new_rps)
          # Refill based on our current rate before we update to the
          # new fill rate
          token_bucket_refill
          @fill_rate = [new_rps, MIN_FILL_RATE].max
          @max_capacity = [new_rps, MIN_CAPACITY].max
          # When we scale down we can't have a current capacity that exceeds our
          # max_capacity.
          @current_capacity = [@current_capacity, @max_capacity].min
        end

        def enable_token_bucket
          @enabled = true
        end

        def update_measured_rate
          t = Aws::Util.monotonic_seconds
          time_bucket = (t * 2).floor / 2.0
          @request_count += 1
          if time_bucket > @last_tx_rate_bucket
            current_rate = @request_count / (time_bucket - @last_tx_rate_bucket)
            @measured_tx_rate = (current_rate * SMOOTH) +
              (@measured_tx_rate * (1 - SMOOTH))
            @request_count = 0
            @last_tx_rate_bucket = time_bucket
          end
        end

        def calculate_time_window
          # This is broken out into a separate calculation because it only
          # gets updated when @last_max_rate changes so it can be cached.
          @time_window = ((@last_max_rate * (1 - BETA)) / SCALE_CONSTANT)**(1.0 / 3)
        end

        def cubic_success(timestamp)
          dt = timestamp - @last_throttle_time
          (SCALE_CONSTANT * ((dt - @time_window)**3)) + @last_max_rate
        end

        def cubic_throttle(rate_to_use)
          rate_to_use * BETA
        end
      end
    end
  end
end
