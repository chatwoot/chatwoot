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
#
# frozen_string_literal: true

require 'java'

module ElasticAPM
  module Metrics
    # @api private
    class JVMSet < Set
      include Logging

      MAX_TRIES = 3

      def initialize(*args)
        super

        @error_count = 0
      end

      def collect
        read!
        super
      end

      def read!
        return if disabled?

        heap = platform_bean.get_heap_memory_usage
        non_heap = platform_bean.get_non_heap_memory_usage

        gauge(:"jvm.memory.heap.used").value = heap.get_used
        gauge(:"jvm.memory.heap.committed").value = heap.get_committed
        gauge(:"jvm.memory.heap.max").value = heap.get_max

        gauge(:"jvm.memory.non_heap.used").value = non_heap.get_used
        gauge(:"jvm.memory.non_heap.committed").value = non_heap.get_committed
        gauge(:"jvm.memory.non_heap.max").value = non_heap.get_max

        pool_beans.each do |bean|
          next unless bean.type.name == "HEAP"

          tags = { name: bean.get_name }

          gauge(:"jvm.memory.heap.pool.used", tags: tags).value = bean.get_usage.get_used
          gauge(:"jvm.memory.heap.pool.committed", tags: tags).value = bean.get_usage.get_committed
          gauge(:"jvm.memory.heap.pool.max", tags: tags).value = bean.get_usage.get_max
        end
      rescue Exception => e
        error("JVM metrics encountered error: %s", e)
        debug("Backtrace:") { e.backtrace.join("\n") }

        @error_count += 1
        if @error_count >= MAX_TRIES
          disable!
          error("Disabling JVM metrics after #{MAX_TRIES} errors", e)
        end
      end

      private

      def platform_bean
        @platform_bean ||= java.lang.management.ManagementFactory.getPlatformMXBean(
          java.lang.management.MemoryMXBean.java_class
        )
      end

      def pool_beans
        @pool_beans ||= java.lang.management.ManagementFactory.getMemoryPoolMXBeans()
      end
    end
  end
end
