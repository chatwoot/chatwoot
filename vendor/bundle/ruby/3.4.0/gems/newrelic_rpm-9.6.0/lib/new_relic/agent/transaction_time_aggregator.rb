# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This module powers the Busy calculation for the Capacity report in
# APM (https://rpm.newrelic.com/accounts/.../applications/.../optimize/capacity_analysis).
#
#               total time spent in transactions this harvest across all threads
# Busy time = ------------------------------------------------------------------------
#             (elapsed time for this harvest cycle) * (# threads that had transactions)
#
module NewRelic
  module Agent
    module TransactionTimeAggregator
      TransactionStats = Struct.new(:transaction_started_at, :elapsed_transaction_time)

      @lock = Mutex.new
      @harvest_cycle_started_at = Process.clock_gettime(Process::CLOCK_REALTIME)

      @stats = Hash.new do |h, k|
        h[k] = TransactionStats.new(nil, 0.0)
      end

      def reset!(timestamp = Process.clock_gettime(Process::CLOCK_REALTIME))
        @harvest_cycle_started_at = timestamp
        @stats.clear
      end

      def transaction_start(timestamp = Process.clock_gettime(Process::CLOCK_REALTIME))
        @lock.synchronize do
          set_transaction_start_time(timestamp)
        end
      end

      def transaction_stop(timestamp = Process.clock_gettime(Process::CLOCK_REALTIME), starting_thread_id = current_thread)
        @lock.synchronize do
          record_elapsed_transaction_time_until(timestamp, starting_thread_id)
          set_transaction_start_time(nil, starting_thread_id)
        end
      end

      INSTANCE_BUSY_METRIC = 'Instance/Busy'.freeze

      def harvest!(timestamp = Process.clock_gettime(Process::CLOCK_REALTIME))
        active_threads = 0
        result = @lock.synchronize do
          # Sum up the transaction times spent in each thread
          elapsed_transaction_time = @stats.inject(0.0) do |total, (thread_id, entry)|
            total + transaction_time_in_thread(timestamp, thread_id, entry)
          end

          active_threads = @stats.size
          elapsed_harvest_time = (timestamp - @harvest_cycle_started_at) * active_threads
          @harvest_cycle_started_at = timestamp

          # Clear out the stats for all threads, _except_ the live ones
          # that have transactions still open (we'll count the rest of
          # those in a future harvest)
          @stats.keep_if do |thread_id, _|
            in_transaction?(thread_id) && thread_is_alive?(thread_id)
          end

          if elapsed_harvest_time > 0.0
            elapsed_transaction_time / elapsed_harvest_time
          else
            0.0
          end
        end

        if Agent.config[:report_instance_busy]
          NewRelic::Agent.record_metric(INSTANCE_BUSY_METRIC, result)
        end

        result
      end

      module_function :reset!,
        :transaction_start,
        :transaction_stop,
        :harvest!

      class << self
        private

        def record_elapsed_transaction_time_until(timestamp, thread_id = current_thread)
          if @stats[thread_id].transaction_started_at
            @stats[thread_id].elapsed_transaction_time +=
              (timestamp - (@stats[thread_id].transaction_started_at || 0.0))
          else
            log_missing_elapsed_transaction_time
          end
        end

        def in_transaction?(thread_id = current_thread)
          !!@stats[thread_id].transaction_started_at
        end

        def current_thread
          Thread.current.object_id
        end

        def thread_is_alive?(thread_id)
          thread = thread_by_id(thread_id)
          # needs else branch coverage
          thread && thread.alive? # rubocop:disable Style/SafeNavigation
        rescue StandardError
          false
        end

        # ObjectSpace is faster on MRI, but disabled by default on JRuby for
        # performance reasons. We have two implementations of `thread_by_id`
        # based on ruby implementation.
        if RUBY_ENGINE == 'jruby'
          def thread_by_id(thread_id)
            Thread.list.detect { |t| t.object_id == thread_id }
          end
        else
          require 'objspace'

          def thread_by_id(thread_id)
            ObjectSpace._id2ref(thread_id)
          end
        end

        def set_transaction_start_time(timestamp, thread_id = current_thread)
          @stats[thread_id].transaction_started_at = timestamp
        end

        def split_transaction_at_harvest(timestamp, thread_id = nil)
          raise ArgumentError, 'thread_id required' unless thread_id

          @stats[thread_id].transaction_started_at = timestamp
          @stats[thread_id].elapsed_transaction_time = 0.0
        end

        def transaction_time_in_thread(timestamp, thread_id, entry)
          return entry.elapsed_transaction_time unless in_transaction?(thread_id)

          # Count the portion of the transaction that's elapsed so far,...
          elapsed = record_elapsed_transaction_time_until(timestamp, thread_id)

          # ...then readjust the transaction start time to the next harvest
          split_transaction_at_harvest(timestamp, thread_id)

          elapsed
        end

        # this method has no test coverage
        def log_missing_elapsed_transaction_time
          # rubocop:disable Style/SafeNavigation
          transaction_name = transaction_name = Tracer.current_transaction &&
            Tracer.current_transaction.best_name ||
            'unknown'
          # rubocop:enable Style/SafeNavigation
          NewRelic::Agent.logger.warn("Unable to calculate elapsed transaction time for #{transaction_name}")
        end
      end
    end
  end
end
