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
  # @api private
  module ChildDurations
    # @api private
    module Methods
      def child_durations
        @child_durations ||= Durations.new
      end

      def child_started
        child_durations.start
      end

      def child_stopped
        child_durations.stop
      end
    end

    # @api private
    class Durations
      def initialize
        @nesting_level = 0
        @start = nil
        @duration = 0
        @mutex = Mutex.new
      end

      attr_reader :duration

      def start
        @mutex.synchronize do
          @nesting_level += 1
          @start = Util.micros if @nesting_level == 1
        end
      end

      def stop
        @mutex.synchronize do
          @nesting_level -= 1
          @duration = (Util.micros - @start) if @nesting_level == 0
        end
      end
    end
  end
end
