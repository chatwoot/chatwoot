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
  module Metrics
    # @api private
    class Metric
      def initialize(
        key,
        initial_value: nil,
        tags: nil,
        reset_on_collect: false
      )
        @key = key
        @initial_value = initial_value
        @value = initial_value
        @tags = tags
        @reset_on_collect = reset_on_collect
        @mutex = Mutex.new
      end

      attr_reader :key, :initial_value, :tags, :value

      def value=(value)
        @mutex.synchronize { @value = value }
      end

      def reset!
        self.value = initial_value
      end

      def tags?
        !!tags&.any?
      end

      def reset_on_collect?
        @reset_on_collect
      end

      def collect
        @mutex.synchronize do
          collected = @value

          return nil if collected.is_a?(Float) && !collected.finite?

          @value = initial_value if reset_on_collect?

          return nil if reset_on_collect? && collected == 0

          collected
        end
      end
    end

    # @api private
    class NoopMetric
      def value; end

      def value=(_); end

      def collect; end

      def reset!; end

      def tags?; end

      def reset_on_collect?; end

      def inc!; end

      def dec!; end

      def update(_, delta: nil); end
    end

    # @api private
    class Counter < Metric
      def initialize(key, initial_value: 0, **args)
        super(key, initial_value: initial_value, **args)
      end

      def inc!
        @mutex.synchronize do
          @value += 1
        end
      end

      def dec!
        @mutex.synchronize do
          @value -= 1
        end
      end
    end

    # @api private
    class Gauge < Metric
      def initialize(key, **args)
        super(key, initial_value: 0, **args)
      end
    end

    # @api private
    class Timer < Metric
      def initialize(key, **args)
        super(key, initial_value: 0, **args)
        @count = 0
      end

      attr_accessor :count

      def update(duration, delta: 0)
        @mutex.synchronize do
          @value += duration
          @count += delta
        end
      end

      def reset!
        @mutex.synchronize do
          @value = 0
          @count = 0
        end
      end
    end
  end
end
