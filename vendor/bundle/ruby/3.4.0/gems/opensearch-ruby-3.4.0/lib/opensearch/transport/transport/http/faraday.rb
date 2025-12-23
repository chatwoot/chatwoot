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
        # The default transport implementation, using the [_Faraday_](https://rubygems.org/gems/faraday)
        # library for abstracting the HTTP client.
        #
        # @see Transport::Base
        #
        class Faraday
          include Base

          # Performs the request by invoking {Transport::Base#perform_request} with a block.
          #
          # @return [Response]
          # @see    Transport::Base#perform_request
          #
          def perform_request(method, path, params = {}, body = nil, headers = nil, opts = {})
            super do |connection, url|
              headers = if connection.connection.headers
                          if headers.nil?
                            connection.connection.headers
                          else
                            connection.connection.headers.merge(headers)
                          end
                        else
                          headers
                        end

              response = connection.connection.run_request(
                method.downcase.to_sym,
                url,
                (body ? __convert_to_json(body) : nil),
                headers
              )

              Response.new response.status, decompress_response(response.body), response.headers
            end
          end

          # Builds and returns a connection
          #
          # @return [Connections::Connection]
          #
          def __build_connection(host, options = {}, block = nil)
            client = ::Faraday.new(__full_url(host), options, &block)
            apply_headers(client, options)
            Connections::Connection.new host: host, connection: client
          end

          # Returns an array of implementation specific connection errors.
          #
          # @return [Array]
          #
          def host_unreachable_exceptions
            [::Faraday::ConnectionFailed, ::Faraday::TimeoutError]
          end

          private

          def user_agent_header(client)
            @user_agent_header ||= begin
              meta = ["RUBY_VERSION: #{RUBY_VERSION}"]
              if RbConfig::CONFIG && RbConfig::CONFIG['host_os']
                meta << "#{RbConfig::CONFIG['host_os'].split('_').first[/[a-z]+/i].downcase} #{RbConfig::CONFIG['target_cpu']}"
              end
              meta << client.headers[USER_AGENT_STR].to_s
              "opensearch-ruby/#{VERSION} (#{meta.join('; ')})"
            end
          end
        end
      end
    end
  end
end
