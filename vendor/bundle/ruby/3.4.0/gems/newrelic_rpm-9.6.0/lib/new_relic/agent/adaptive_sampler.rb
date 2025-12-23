# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class AdaptiveSampler
      def initialize(target_samples = 10, period_duration = 60)
        @target = target_samples
        @seen = 0
        @seen_last = 0
        @sampled_count = 0
        @period_duration = period_duration
        @first_period = true
        @period_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @lock = Mutex.new
        register_config_callbacks
      end

      # Called at the beginning of each transaction, increments seen and
      # returns a boolean indicating if we should mark the transaction as
      # sampled. This uses the adaptive sampling algorithm.
      def sampled?
        @lock.synchronize do
          reset_if_period_expired!
          sampled = if @first_period
            @sampled_count < 10
          elsif @sampled_count < @target
            rand(@seen_last) < @target
          else
            # you've met the target and need to exponentially back off
            rand(@seen) < exponential_backoff
          end

          @sampled_count += 1 if sampled
          @seen += 1

          sampled
        end
      end

      def exponential_backoff
        @target**(@target.to_f / @sampled_count) - @target**0.5
      end

      def stats
        @lock.synchronize do
          {
            target: @target,
            seen: @seen,
            seen_last: @seen_last,
            sampled_count: @sampled_count
          }
        end
      end

      private

      def reset_if_period_expired!
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        return unless @period_start + @period_duration <= now

        elapsed_periods = Integer((now - @period_start) / @period_duration)
        @period_start += elapsed_periods * @period_duration

        @first_period = false
        @seen_last = elapsed_periods > 1 ? 0 : @seen
        @seen = 0
        @sampled_count = 0
      end

      def register_config_callbacks
        register_sampling_target_callback
        register_sampling_period_callback
      end

      def register_sampling_target_callback
        NewRelic::Agent.config.register_callback(:sampling_target) do |target|
          target_changed = false
          @lock.synchronize do
            if @target != target
              @target = target
              target_changed = true
            end
          end
          if target_changed
            NewRelic::Agent.logger.debug("Sampling target set to: #{target}")
          end
        end
      end

      def register_sampling_period_callback
        NewRelic::Agent.config.register_callback(:sampling_target_period_in_seconds) do |period_duration|
          period_changed = false
          @lock.synchronize do
            if @period_duration != period_duration
              @period_duration = period_duration
              period_changed = true
            end
          end
          if period_changed
            NewRelic::Agent.logger.debug("Sampling period set to: #{period_duration}")
          end
        end
      end
    end
  end
end
