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
  module Transport
    # @api private
    class Worker
      include Logging

      class << self
        def adapter
          @adapter ||= Connection
        end

        attr_writer :adapter
      end

      # @api private
      class StopMessage; end

      # @api private
      class FlushMessage; end

      def initialize(
        config,
        queue,
        serializers:,
        filters:
      )
        @config = config
        @queue = queue

        @serializers = serializers
        @filters = filters

        @connection = self.class.adapter.new(config)
      end

      attr_reader :queue, :filters, :name, :connection, :serializers

      def work_forever
        while (msg = queue.pop)
          case msg
          when StopMessage
            debug 'Stopping worker [%s]', self
            connection.flush(:halt)
            break
          else
            process msg
          end
        end
      rescue Exception => e
        warn 'Worker died with exception: %s', e.inspect
        debug e.backtrace.join("\n")
      end

      def process(resource)
        return unless (json = serialize_and_filter(resource))
        connection.write(json)
      end

      private

      def serialize_and_filter(resource)
        if resource.respond_to?(:prepare_for_serialization!)
          resource.prepare_for_serialization!
        end

        serialized = serializers.serialize(resource)

        # if a filter returns nil, it means skip the event
        return nil if @filters.apply!(serialized) == Filters::SKIP

        JSON.fast_generate(serialized)
      rescue Exception
        error format('Failed converting event to JSON: %s', resource.inspect)
        error serialized.inspect
        nil
      end
    end
  end
end
