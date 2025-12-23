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
    class Connection
      include Logging

      # A connection holds an instance `http` of an Http::Connection.
      #
      # The HTTP::Connection itself is not thread safe.
      #
      # The connection sends write requests and close requests to `http`, and
      # has to ensure no write requests are sent after closing `http`.
      #
      # The connection schedules a separate thread to close an `http`
      # connection some time in the future. To avoid the thread interfering
      # with ongoing write requests to `http`, write and close
      # requests have to be synchronized.

      def initialize(config)
        @config = config
        @metadata = JSON.fast_generate(
          Serializers::MetadataSerializer.new(config).build(
            Metadata.new(config)
          )
        )
        @url = "#{config.server_url}/intake/v2/events"
        @mutex = Mutex.new
      end

      attr_reader :http

      def write(str)
        return false if @config.disable_send

        begin
          bytes_written = 0

          # The request might get closed from timertask so let's make sure we
          # hold it open until we've written.
          @mutex.synchronize do
            connect if http.nil? || http.closed?
            bytes_written = http.write(str)
          end

          flush(:api_request_size) if bytes_written >= @config.api_request_size
        rescue IOError => e
          error('Connection error: %s', e.inspect)
          flush(:ioerror)
        rescue Errno::EPIPE => e
          error('Connection error: %s', e.inspect)
          flush(:broken_pipe)
        rescue Exception => e
          error('Connection error: %s', e.inspect)
          flush(:connection_error)
        end
      end

      def flush(reason = :force)
        # Could happen from the timertask so we need to sync
        @mutex.synchronize do
          return if http.nil?
          http.close(reason)
        end
      end

      def inspect
        format(
          '<%s url:%s closed:%s >',
          super.split.first, @url, http&.closed?
        )
      end

      private

      def connect
        schedule_closing if @config.api_request_time

        @http =
          Http.open(@config, @url).tap do |http|
            http.write(@metadata)
          end
      end
      # rubocop:enable

      def schedule_closing
        @close_task&.cancel
        @close_task =
          Concurrent::ScheduledTask.execute(@config.api_request_time) do
            flush(:scheduled_flush)
          end
      end
    end
  end
end
