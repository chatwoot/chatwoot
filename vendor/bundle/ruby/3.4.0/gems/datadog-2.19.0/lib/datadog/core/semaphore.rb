# frozen_string_literal: true

module Datadog
  module Core
    # Semaphore pattern implementation, as described in documentation for
    # ConditionVariable.
    #
    # @api private
    class Semaphore
      def initialize
        @wake_lock = Mutex.new
        @wake = ConditionVariable.new
      end

      def signal
        wake_lock.synchronize do
          wake.signal
        end
      end

      def wait(timeout = nil)
        wake_lock.synchronize do
          # steep specifies that the second argument to wait is of type
          # ::Time::_Timeout which for some reason is not Numeric and is not
          # castable from Numeric.
          wake.wait(wake_lock, timeout) # steep:ignore
        end
      end

      private

      attr_reader :wake_lock, :wake
    end
  end
end
