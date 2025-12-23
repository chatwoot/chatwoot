# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
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

module OpenSearch
  module Transport
    module Transport
      module HTTP
        # Alternative HTTP transport implementation, using the [_Curb_](https://rubygems.org/gems/curb) client.
        #
        # @see Transport::Base
        #
        class Curb
          include Base

          # Performs the request by invoking {Transport::Base#perform_request} with a block.
          #
          # @return [Response]
          # @see    Transport::Base#perform_request
          #
          def perform_request(method, path, params = {}, body = nil, headers = nil, opts = {})
            super do |connection, _url|
              connection.connection.url = connection.full_url(path, params)

              case method
              when 'HEAD'
                connection.connection.set :nobody, true
              when 'GET', 'POST', 'PUT', 'DELETE'
                connection.connection.set :nobody, false
                connection.connection.put_data = __convert_to_json(body) if body
                if headers
                  if connection.connection.headers
                    connection.connection.headers.merge!(headers)
                  else
                    connection.connection.headers = headers
                  end
                end
              else
                raise ArgumentError, "Unsupported HTTP method: #{method}"
              end

              connection.connection.http(method.to_sym)

              Response.new(
                connection.connection.response_code,
                decompress_response(connection.connection.body_str),
                headers(connection)
              )
            end
          end

          def headers(connection)
            headers_string = connection.connection.header_str
            return nil if headers_string.nil?

            response_headers = headers_string&.split(/\\r\\n|\r\n/)&.reject(&:empty?)
            response_headers.shift # Removes HTTP status string
            processed_header = response_headers.flat_map { |s| s.scan(/^(\S+): (.+)/) }
            headers_hash = processed_header.to_h.transform_keys(&:downcase)
            if headers_hash['content-type']&.match?(%r{application/json})
              headers_hash['content-type'] = 'application/json'
            end
            headers_hash
          end

          # Builds and returns a connection
          #
          # @return [Connections::Connection]
          #
          def __build_connection(host, options = {}, block = nil)
            client = ::Curl::Easy.new
            apply_headers(client, options)
            client.url = __full_url(host)

            if host[:user]
              client.http_auth_types = host[:auth_type] || :basic
              client.username = host[:user]
              client.password = host[:password]
            end

            client.instance_eval(&block) if block

            Connections::Connection.new host: host, connection: client
          end

          # Returns an array of implementation specific connection errors.
          #
          # @return [Array]
          #
          def host_unreachable_exceptions
            [
              ::Curl::Err::HostResolutionError,
              ::Curl::Err::ConnectionFailedError,
              ::Curl::Err::GotNothingError,
              ::Curl::Err::RecvError,
              ::Curl::Err::SendError,
              ::Curl::Err::TimeoutError
            ]
          end

          private

          def user_agent_header(_client)
            @user_agent_header ||= begin
              meta = ["RUBY_VERSION: #{RUBY_VERSION}"]
              if RbConfig::CONFIG && RbConfig::CONFIG['host_os']
                meta << "#{RbConfig::CONFIG['host_os'].split('_').first[/[a-z]+/i].downcase} #{RbConfig::CONFIG['target_cpu']}"
              end
              meta << "Curb #{Curl::CURB_VERSION}"
              "opensearch-ruby/#{VERSION} (#{meta.join('; ')})"
            end
          end
        end
      end
    end
  end
end
