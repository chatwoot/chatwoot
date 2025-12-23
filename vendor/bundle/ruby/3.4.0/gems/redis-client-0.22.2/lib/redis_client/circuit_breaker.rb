# frozen_string_literal: true

class RedisClient
  class CircuitBreaker
    module Middleware
      def connect(config)
        config.circuit_breaker.protect { super }
      end

      def call(_command, config)
        config.circuit_breaker.protect { super }
      end

      def call_pipelined(_commands, config)
        config.circuit_breaker.protect { super }
      end
    end

    OpenCircuitError = Class.new(CannotConnectError)

    attr_reader :error_timeout, :error_threshold, :error_threshold_timeout, :success_threshold

    def initialize(error_threshold:, error_timeout:, error_threshold_timeout: error_timeout, success_threshold: 0)
      @error_threshold = Integer(error_threshold)
      @error_threshold_timeout = Float(error_threshold_timeout)
      @error_timeout = Float(error_timeout)
      @success_threshold = Integer(success_threshold)
      @errors = []
      @successes = 0
      @state = :closed
      @lock = Mutex.new
    end

    def protect
      if @state == :open
        refresh_state
      end

      case @state
      when :open
        raise OpenCircuitError, "Too many connection errors happened recently"
      when :closed
        begin
          yield
        rescue ConnectionError
          record_error
          raise
        end
      when :half_open
        begin
          result = yield
          record_success
          result
        rescue ConnectionError
          record_error
          raise
        end
      else
        raise "[BUG] RedisClient::CircuitBreaker unexpected @state (#{@state.inspect}})"
      end
    end

    private

    def refresh_state
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @lock.synchronize do
        if @errors.last < (now - @error_timeout)
          if @success_threshold > 0
            @state = :half_open
            @successes = 0
          else
            @errors.clear
            @state = :closed
          end
        end
      end
    end

    def record_error
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expiry = now - @error_timeout
      @lock.synchronize do
        if @state == :closed
          @errors.reject! { |t| t < expiry }
        end
        @errors << now
        @successes = 0
        if @state == :half_open || (@state == :closed && @errors.size >= @error_threshold)
          @state = :open
        end
      end
    end

    def record_success
      return unless @state == :half_open

      @lock.synchronize do
        return unless @state == :half_open

        @successes += 1
        if @successes >= @success_threshold
          @state = :closed
        end
      end
    end
  end
end
