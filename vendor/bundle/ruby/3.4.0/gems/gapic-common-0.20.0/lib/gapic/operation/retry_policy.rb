# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Gapic
  class Operation
    ##
    # The policy for retrying operation reloads using an incremental backoff. A new object instance should be used for
    # every Operation invocation.
    #
    class RetryPolicy
      ##
      # Create new Operation RetryPolicy.
      #
      # @param initial_delay [Numeric] client-side timeout
      # @param multiplier [Numeric] client-side timeout
      # @param max_delay [Numeric] client-side timeout
      # @param timeout [Numeric] client-side timeout
      #
      def initialize initial_delay: nil, multiplier: nil, max_delay: nil, timeout: nil
        @initial_delay = initial_delay
        @multiplier    = multiplier
        @max_delay     = max_delay
        @timeout       = timeout
        @delay         = nil
      end

      def initial_delay
        @initial_delay || 10
      end

      def multiplier
        @multiplier || 1.3
      end

      def max_delay
        @max_delay || 300 # Five minutes
      end

      def timeout
        @timeout || 3600 # One hour
      end

      def call
        return unless retry?

        delay!
        increment_delay!

        true
      end

      private

      def deadline
        # memoize the deadline
        @deadline ||= Time.now + timeout
      end

      def retry?
        deadline > Time.now
      end

      ##
      # The current delay value.
      def delay
        @delay || initial_delay
      end

      def delay!
        # Call Kernel.sleep so we can stub it.
        Kernel.sleep delay
      end

      ##
      # Calculate and set the next delay value.
      def increment_delay!
        @delay = [delay * multiplier, max_delay].min
      end
    end
  end
end
