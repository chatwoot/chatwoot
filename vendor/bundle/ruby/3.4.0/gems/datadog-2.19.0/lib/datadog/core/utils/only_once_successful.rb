# frozen_string_literal: true

require_relative 'only_once'

module Datadog
  module Core
    module Utils
      # Helper class to execute something with only one successful execution.
      #
      # If limit is not provided to the constructor, +run+ will execute the
      # block an unlimited number of times until the block indicates that it
      # executed successfully by returning a truthy value. After a block
      # executes successfully, subsequent +run+ calls will not invoke the
      # block.
      #
      # If a non-zero limit is provided to the constructor, +run+ will
      # execute the block up to that many times, and will mark the instance
      # of OnlyOneSuccessful as failed if none of the executions succeeded.
      #
      # One consumer of this class is sending the app-started telemetry event.
      #
      # Successful execution is determined by the return value of the block:
      # any truthy value is considered success.
      #
      # This class is thread-safe (however, instances of it must also be
      # created in a thread-safe manner).
      #
      # Note: In its current state, this class is not Ractor-safe.
      # In https://github.com/DataDog/dd-trace-rb/pull/1398#issuecomment-797378810 we have a discussion of alternatives,
      # including an alternative implementation that is Ractor-safe once spent.
      class OnlyOnceSuccessful < OnlyOnce
        def initialize(limit = 0)
          super()

          @limit = limit
          @failed = false
          @retries = 0
        end

        def run
          @mutex.synchronize do
            return if @ran_once

            result = yield
            @ran_once = !!result

            if !@ran_once && limited?
              @retries += 1
              check_limit!
            end

            result
          end
        end

        def success?
          @mutex.synchronize { @ran_once && !@failed }
        end

        def failed?
          @mutex.synchronize { @ran_once && @failed }
        end

        private

        def check_limit!
          if @retries >= @limit
            @failed = true
            @ran_once = true
          end
        end

        def limited?
          !@limit.nil? && @limit.positive?
        end

        def reset_ran_once_state_for_tests
          @mutex.synchronize do
            @ran_once = false
            @failed = false
            @retries = 0
          end
        end
      end
    end
  end
end
