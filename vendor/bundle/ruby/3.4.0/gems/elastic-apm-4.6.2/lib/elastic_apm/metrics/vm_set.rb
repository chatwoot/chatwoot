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
    class VMSet < Set
      include Logging

      def collect
        read!
        super
      end

      def read!
        return if disabled?

        stat = GC.stat

        gauge(:'ruby.gc.count').value = stat[:count]
        gauge(:'ruby.threads').value = Thread.list.count
        gauge(:'ruby.heap.slots.live').value = stat[:heap_live_slots]

        gauge(:'ruby.heap.slots.free').value = stat[:heap_free_slots]
        gauge(:'ruby.heap.allocations.total').value =
          stat[:total_allocated_objects]

        return unless GC::Profiler.enabled?

        @total_time ||= 0
        @total_time += GC::Profiler.total_time
        GC::Profiler.clear
        gauge(:'ruby.gc.time').value = @total_time
      rescue TypeError => e
        error 'VM metrics encountered error: %s', e
        debug('Backtrace:') { e.backtrace.join("\n") }

        disable!
      end
    end
  end
end
