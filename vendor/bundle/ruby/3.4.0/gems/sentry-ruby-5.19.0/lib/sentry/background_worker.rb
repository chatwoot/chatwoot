# frozen_string_literal: true

require "concurrent/executor/thread_pool_executor"
require "concurrent/executor/immediate_executor"
require "concurrent/configuration"

module Sentry
  class BackgroundWorker
    include LoggingHelper

    attr_reader :max_queue, :number_of_threads
    # @deprecated Use Sentry.logger to retrieve the current logger instead.
    attr_reader :logger
    attr_accessor :shutdown_timeout

    DEFAULT_MAX_QUEUE = 30

    def initialize(configuration)
      @shutdown_timeout = 1
      @number_of_threads = configuration.background_worker_threads
      @max_queue = configuration.background_worker_max_queue
      @logger = configuration.logger
      @debug = configuration.debug
      @shutdown_callback = nil

      @executor =
        if configuration.async
          log_debug("config.async is set, BackgroundWorker is disabled")
          Concurrent::ImmediateExecutor.new
        elsif @number_of_threads == 0
          log_debug("config.background_worker_threads is set to 0, all events will be sent synchronously")
          Concurrent::ImmediateExecutor.new
        else
          log_debug("Initializing the Sentry background worker with #{@number_of_threads} threads")

          executor = Concurrent::ThreadPoolExecutor.new(
            min_threads: 0,
            max_threads: @number_of_threads,
            max_queue: @max_queue,
            fallback_policy: :discard
          )

          @shutdown_callback = proc do
            executor.shutdown
            executor.wait_for_termination(@shutdown_timeout)
          end

          executor
        end
    end

    # if you want to monkey-patch this method, please override `_perform` instead
    def perform(&block)
      @executor.post do
        begin
          _perform(&block)
        rescue Exception => e
          log_error("exception happened in background worker", e, debug: @debug)
        end
      end
    end

    def shutdown
      log_debug("Shutting down background worker")
      @shutdown_callback&.call
    end

    def full?
      @executor.is_a?(Concurrent::ThreadPoolExecutor) &&
        @executor.remaining_capacity == 0
    end

    private

    def _perform(&block)
      block.call
    end
  end
end
