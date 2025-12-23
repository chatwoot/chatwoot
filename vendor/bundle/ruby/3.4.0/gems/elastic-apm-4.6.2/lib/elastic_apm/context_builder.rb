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
  class ContextBuilder
    MAX_BODY_LENGTH = 2048
    SKIPPED = '[SKIPPED]'

    def initialize(config)
      @config = config
    end

    attr_reader :config

    def build(rack_env:, for_type:)
      Context.new.tap do |context|
        apply_to_request(context, rack_env: rack_env, for_type: for_type)
      end
    end

    private

    def apply_to_request(context, rack_env:, for_type:)
      req = rails_req?(rack_env) ? rack_env : Rack::Request.new(rack_env)

      context.request = Context::Request.new unless context.request
      request = context.request

      request.socket = Context::Request::Socket.new(req)
      request.http_version = build_http_version rack_env
      request.method = req.request_method
      request.url = Context::Request::Url.new(req)

      request.body = should_capture_body?(for_type) ? get_body(req) : SKIPPED

      headers, env = get_headers_and_env(rack_env)
      request.headers = headers if config.capture_headers?
      request.env = env if config.capture_env?

      request.cookies = req.cookies.dup

      context
    end

    def should_capture_body?(for_type)
      option = config.capture_body

      return true if option == 'all'
      return true if option == 'transactions' && for_type == :transaction
      return true if option == 'errors' && for_type == :error

      false
    end

    def get_body(req)
      case req.media_type
      when 'application/x-www-form-urlencoded', 'multipart/form-data'
        req.POST.dup
      else
        body = req.body.read
        req.body.rewind
        body.byteslice(0, MAX_BODY_LENGTH).force_encoding('utf-8').scrub
      end
    end

    def rails_req?(env)
      defined?(ActionDispatch::Request) && env.is_a?(ActionDispatch::Request)
    end

    def get_headers_and_env(rack_env)
      # In Rails < 5 ActionDispatch::Request inherits from Hash
      headers =
        rack_env.respond_to?(:headers) ? rack_env.headers : rack_env

      headers.each_with_object([{}, {}]) do |(key, value), (http, env)|
        next unless key == key.upcase

        if key.start_with?('HTTP_')
          http[camel_key(key)] = value
        else
          env[key] = value
        end
      end
    end

    def camel_key(key)
      key.gsub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
    end

    def build_http_version(rack_env)
      return unless (http_version = rack_env['HTTP_VERSION'])
      http_version.gsub(%r{HTTP/}, '')
    end
  end
end
