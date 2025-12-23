# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

module ElasticAPM
  module Util
    # @api private

    # Usage example:
    #   Throttle.new(5) { thing to only do once per 5 secs }
    class Throttle
      def initialize(buffer_secs, &block)
        @buffer_secs = buffer_secs
        @block = block
      end

      def call
        if @last_call && seconds_since_last_call < @buffer_secs
          return @last_result
        end

        @last_call = now
        @last_result = @block.call
      end

      private

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def seconds_since_last_call
        now - @last_call
      end
    end
  end
end
