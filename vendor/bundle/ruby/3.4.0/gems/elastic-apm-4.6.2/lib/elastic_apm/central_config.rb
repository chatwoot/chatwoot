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

require 'elastic_apm/central_config/cache_control'

# rubocop:disable Style/AccessorGrouping
module ElasticAPM
  # @api private
  class CentralConfig
    include Logging

    # @api private
    class ResponseError < InternalError
      def initialize(response)
        super
        @response = response
      end

      attr_reader :response
    end
    class ClientError < ResponseError; end
    class ServerError < ResponseError; end

    DEFAULT_MAX_AGE = 300

    def initialize(config)
      @config = config
      @modified_options = {}
      @http = Transport::Connection::Http.new(config)
      @etag = 1
    end

    attr_reader :config
    attr_reader :scheduled_task, :promise # for specs

    def start
      return unless config.central_config?

      debug 'Starting CentralConfig'

      fetch_and_apply_config
    end

    def stop
      debug 'Stopping CentralConfig'

      @scheduled_task&.cancel
    end

    def fetch_and_apply_config
      @promise =
        Concurrent::Promise
        .execute { fetch_config }
        .on_success { |resp| handle_success(resp) }
        .rescue { |err| handle_error(err) }
    end

    def fetch_config
      resp = perform_request

      # rubocop:disable Lint/DuplicateBranch
      case resp.status
      when 200..299
        resp
      when 300..399
        resp
      when 400..499
        raise ClientError, resp
      when 500..599
        raise ServerError, resp
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    def assign(update)
      # For each updated option, store the original value,
      # unless already stored
      update.each_key do |key|
        @modified_options[key] ||= config.get(key.to_sym)&.value
      end

      # If the new update doesn't set a previously modified option,
      # revert it to the original
      @modified_options.each_key do |key|
        next if update.key?(key)
        update[key] = @modified_options.delete(key)
      end

      @config.replace_options(update)
    end

    def handle_forking!
      stop
      start
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def handle_success(resp)
      if (etag = resp.headers['Etag'])
        @etag = etag
      end

      if resp.status == 304
        debug 'Received 304 Not Modified'
      else
        if resp.body && !resp.body.empty?
          update = JSON.parse(resp.body.to_s)
          assign(update)
        end

        if update&.any?
          info 'Updated config from Kibana'
          debug 'Modified: %s', update.inspect
          debug 'Modified original options: %s', @modified_options.inspect
        end
      end

      schedule_next_fetch(resp)

      true
    rescue Exception => e
      error 'Failed to apply remote config, %s', e.inspect
      debug { e.backtrace.join('\n') }
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def handle_error(error)
      # For tests, WebMock failures don't have real responses
      response = error.response if error.respond_to?(:response)

      debug(
        'Failed fetching config: %s, trying again in %d seconds',
        response&.body, DEFAULT_MAX_AGE
      )

      assign({})

      schedule_next_fetch(response)
    end

    def perform_request
      @http.get(server_url, headers: headers)
    end

    def server_url
      @server_url ||=
        config.server_url +
        '/config/v1/agents' \
        "?service.name=#{CGI.escape(config.service_name)}" \
        "&service.environment=#{CGI.escape(config.environment || '')}"
    end

    def headers
      { 'If-None-Match': @etag }
    end

    def schedule_next_fetch(resp = nil)
      headers = resp&.headers
      seconds =
        if headers && headers['Cache-Control']
          CacheControl.new(headers['Cache-Control']).max_age
        else
          DEFAULT_MAX_AGE
        end

      if seconds < 5
        debug "Next fetch is too low (#{seconds}s) - increasing to default"
        seconds = 5
      end

      @scheduled_task =
        Concurrent::ScheduledTask
        .execute(seconds) { fetch_and_apply_config }
    end
  end
end
# rubocop:enable Style/AccessorGrouping
