# frozen_string_literal: true

require "time"
require "sidekiq"
require "sidekiq/metrics/shared"

# This file contains the components which track execution metrics within Sidekiq.
module Sidekiq
  module Metrics
    class ExecutionTracker
      include Sidekiq::Component

      def initialize(config)
        @config = config
        @jobs = Hash.new(0)
        @totals = Hash.new(0)
        @grams = Hash.new { |hash, key| hash[key] = Histogram.new(key) }
        @lock = Mutex.new
      end

      def track(queue, klass)
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :millisecond)
        time_ms = 0
        begin
          begin
            yield
          ensure
            finish = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :millisecond)
            time_ms = finish - start
          end
          # We don't track time for failed jobs as they can have very unpredictable
          # execution times. more important to know average time for successful jobs so we
          # can better recognize when a perf regression is introduced.
          track_time(klass, time_ms)
        rescue JobRetry::Skip
          # This is raised when iterable job is interrupted.
          track_time(klass, time_ms)
          raise
        rescue Exception
          @lock.synchronize {
            @jobs["#{klass}|f"] += 1
            @totals["f"] += 1
          }
          raise
        ensure
          @lock.synchronize {
            @jobs["#{klass}|p"] += 1
            @totals["p"] += 1
          }
        end
      end

      # LONG_TERM = 90 * 24 * 60 * 60
      # MID_TERM = 7 * 24 * 60 * 60
      SHORT_TERM = 8 * 60 * 60

      def flush(time = Time.now)
        totals, jobs, grams = reset
        procd = totals["p"]
        fails = totals["f"]
        return if procd == 0 && fails == 0

        now = time.utc
        # nowdate = now.strftime("%Y%m%d")
        # nowhour = now.strftime("%Y%m%d|%-H")
        nowmin = now.strftime("%Y%m%d|%-H:%-M")
        count = 0

        redis do |conn|
          # persist fine-grained histogram data
          if grams.size > 0
            conn.pipelined do |pipe|
              grams.each do |_, gram|
                gram.persist(pipe, now)
              end
            end
          end

          # persist coarse grained execution count + execution millis.
          # note as of today we don't use or do anything with the
          # daily or hourly rollups.
          [
            # ["j", jobs, nowdate, LONG_TERM],
            # ["j", jobs, nowhour, MID_TERM],
            ["j", jobs, nowmin, SHORT_TERM]
          ].each do |prefix, data, bucket, ttl|
            conn.pipelined do |xa|
              stats = "#{prefix}|#{bucket}"
              data.each_pair do |key, value|
                xa.hincrby stats, key, value
                count += 1
              end
              xa.expire(stats, ttl)
            end
          end
          logger.debug "Flushed #{count} metrics"
          count
        end
      end

      private

      def track_time(klass, time_ms)
        @lock.synchronize {
          @grams[klass].record_time(time_ms)
          @jobs["#{klass}|ms"] += time_ms
          @totals["ms"] += time_ms
        }
      end

      def reset
        @lock.synchronize {
          array = [@totals, @jobs, @grams]
          reset_instance_variables
          array
        }
      end

      def reset_instance_variables
        @totals = Hash.new(0)
        @jobs = Hash.new(0)
        @grams = Hash.new { |hash, key| hash[key] = Histogram.new(key) }
      end
    end

    class Middleware
      include Sidekiq::ServerMiddleware

      def initialize(options)
        @exec = options
      end

      def call(_instance, hash, queue, &block)
        @exec.track(queue, hash["wrapped"] || hash["class"], &block)
      end
    end
  end
end

Sidekiq.configure_server do |config|
  exec = Sidekiq::Metrics::ExecutionTracker.new(config)
  config.server_middleware do |chain|
    chain.add Sidekiq::Metrics::Middleware, exec
  end
  config.on(:beat) do
    exec.flush
  end
end
