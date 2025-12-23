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
    module Serializers
      # @api private
      class ContextSerializer < Serializer
        def build(context)
          return nil if context.nil? || context.empty?

          {
            custom: context.custom,
            tags: mixed_object(context.labels),
            request: build_request(context.request),
            response: build_response(context.response),
            user: build_user(context.user),
            service: build_service(context.service)
          }
        end

        private

        def build_request(request)
          return unless request

          {
            body: request.body,
            cookies: request.cookies,
            env: request.env,
            headers: request.headers,
            http_version: keyword_field(request.http_version),
            method: keyword_field(request.method),
            socket: build_socket(request.socket),
            url: build_url(request.url)
          }
        end

        def build_response(response)
          return unless response

          {
            status_code: response.status_code.to_i,
            headers: response.headers,
            headers_sent: response.headers_sent,
            finished: response.finished
          }
        end

        def build_user(user)
          return if !user || user.empty?

          {
            id: keyword_field(user.id),
            email: keyword_field(user.email),
            username: keyword_field(user.username)
          }
        end

        def build_socket(socket)
          return unless socket

          {
            remote_addr: socket.remote_addr
          }
        end

        def build_url(url)
          return unless url

          {
            protocol: keyword_field(url.protocol),
            full: keyword_field(url.full),
            hostname: keyword_field(url.hostname),
            port: keyword_field(url.port),
            pathname: keyword_field(url.pathname),
            search: keyword_field(url.search),
            hash: keyword_field(url.hash)
          }
        end

        def build_service(service)
          return unless service

          {
            framework: {
              name: keyword_field(service.framework.name),
              version: keyword_field(service.framework.version)
            }
          }
        end
      end
    end
  end
end
