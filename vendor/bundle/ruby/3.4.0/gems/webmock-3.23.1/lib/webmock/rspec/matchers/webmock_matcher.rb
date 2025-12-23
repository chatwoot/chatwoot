# frozen_string_literal: true

module WebMock
  class WebMockMatcher

    def initialize(method, uri)
      @request_execution_verifier = RequestExecutionVerifier.new
      @request_execution_verifier.request_pattern = RequestPattern.new(method, uri)
    end

    def once
      @request_execution_verifier.expected_times_executed = 1
      self
    end

    def twice
      @request_execution_verifier.expected_times_executed = 2
      self
    end

    def at_least_once
      @request_execution_verifier.at_least_times_executed = 1
      self
    end

    def at_least_twice
      @request_execution_verifier.at_least_times_executed = 2
      self
    end

    def at_least_times(times)
      @request_execution_verifier.at_least_times_executed = times
      self
    end

    def with(options = {}, &block)
      @request_execution_verifier.request_pattern.with(options, &block)
      self
    end

    def times(times)
      @request_execution_verifier.expected_times_executed = times.to_i
      self
    end

    def matches?(webmock)
      @request_execution_verifier.matches?
    end

    def does_not_match?(webmock)
      @request_execution_verifier.does_not_match?
    end

    def failure_message
      @request_execution_verifier.failure_message
    end

    def failure_message_when_negated
      @request_execution_verifier.failure_message_when_negated
    end

    def description
      @request_execution_verifier.description
    end

    # RSpec 2 compatibility:
    alias_method :negative_failure_message, :failure_message_when_negated
  end
end
