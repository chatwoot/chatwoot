# frozen_string_literal: true

module Sentry
  class ThreadedPeriodicWorker
    include LoggingHelper

    def initialize(logger, internal)
      @thread = nil
      @exited = false
      @interval = internal
      @logger = logger
    end

    def ensure_thread
      return false if @exited
      return true if @thread&.alive?

      @thread = Thread.new do
        loop do
          sleep(@interval)
          run
        end
      end

      true
    rescue ThreadError
      log_debug("[#{self.class.name}] thread creation failed")
      @exited = true
      false
    end

    def kill
      log_debug("[#{self.class.name}] thread killed")

      @exited = true
      @thread&.kill
    end
  end
end
