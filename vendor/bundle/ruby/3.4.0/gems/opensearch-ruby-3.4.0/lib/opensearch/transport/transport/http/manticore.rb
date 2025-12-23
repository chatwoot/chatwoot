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

require 'manticore'

module OpenSearch
  module Transport
    module Transport
      module HTTP
        # Alternative HTTP transport implementation for JRuby,
        # using the [_Manticore_](https://github.com/cheald/manticore) client,
        #
        # @example HTTP
        #
        #     require 'opensearch/transport/transport/http/manticore'
        #
        #     client = OpenSearch::Client.new transport_class: OpenSearch::Transport::Transport::HTTP::Manticore
        #
        #     client.transport.connections.first.connection
        #     => #<Manticore::Client:0x56bf7ca6 ...>
        #
        #     client.info['status']
        #     => 200
        #
        #  @example HTTPS (All SSL settings are optional,
        #                  see http://www.rubydoc.info/gems/manticore/Manticore/Client:initialize)
        #
        #     require 'opensearch/transport/transport/http/manticore'
        #
        #     client = OpenSearch::Client.new \
        #       url: 'https://opensearch.example.com',
        #       transport_class: OpenSearch::Transport::Transport::HTTP::Manticore,
        #       ssl: {
        #         truststore: '/tmp/truststore.jks',
        #         truststore_password: 'password',
        #         keystore: '/tmp/keystore.jks',
        #         keystore_password: 'secret',
        #       }
        #
        #     client.transport.connections.first.connection
        #     => #<Manticore::Client:0xdeadbeef ...>
        #
        #     client.info['status']
        #     => 200
        #
        # @see Transport::Base
        #
        class Manticore
          include Base

          def initialize(arguments = {}, &block)
            @manticore = build_client(arguments[:options] || {})
            super(arguments, &block)
          end

          # Should just be run once at startup
          def build_client(options = {})
            client_options = options[:transport_options] || {}
            client_options[:ssl] = options[:ssl] || {}

            @manticore = ::Manticore::Client.new(client_options)
          end

          # Performs the request by invoking {Transport::Base#perform_request} with a block.
          #
          # @return [Response]
          # @see    Transport::Base#perform_request
          #
          def perform_request(method, path, params = {}, body = nil, headers = nil, opts = {})
            super do |connection, url|
              params[:body] = __convert_to_json(body) if body
              params[:headers] = headers if headers
              params = params.merge @request_options
              case method
              when "GET"
                resp = connection.connection.get(url, params)
              when "HEAD"
                resp = connection.connection.head(url, params)
              when "PUT"
                resp = connection.connection.put(url, params)
              when "POST"
                resp = connection.connection.post(url, params)
              when "DELETE"
                resp = connection.connection.delete(url, params)
              else
                raise ArgumentError, "Method #{method} not supported"
              end
              Response.new resp.code, resp.read_body, resp.headers
            end
          end

          # Builds and returns a collection of connections.
          # Each connection is a Manticore::Client
          #
          # @return [Connections::Collection]
          #
          def __build_connections
            @request_options = {}
            apply_headers(@request_options, options[:transport_options])
            apply_headers(@request_options, options)

            Connections::Collection.new \
              connections: hosts.map { |host|
                host[:protocol]   = host[:scheme] || DEFAULT_PROTOCOL
                host[:port]     ||= DEFAULT_PORT

                host.delete(:user)     # auth is not supported here.
                host.delete(:password) # use the headers

                Connections::Connection.new \
                  host: host,
                  connection: @manticore
              },
              selector_class: options[:selector_class],
              selector: options[:selector]
          end

          # Closes all connections by marking them as dead
          # and closing the underlying HttpClient instances
          #
          # @return [Connections::Collection]
          #
          def __close_connections
            # The Manticore adapter uses a single long-lived instance
            # of Manticore::Client, so we don't close the connections.
          end

          # Returns an array of implementation specific connection errors.
          #
          # @return [Array]
          #
          def host_unreachable_exceptions
            [
              ::Manticore::Timeout,
              ::Manticore::SocketException,
              ::Manticore::ClientProtocolException,
              ::Manticore::ResolutionFailure
            ]
          end

          private

          def apply_headers(request_options, options)
            headers = (options && options[:headers]) || {}
            headers[CONTENT_TYPE_STR] = find_value(headers, CONTENT_TYPE_REGEX) || DEFAULT_CONTENT_TYPE
            headers[USER_AGENT_STR] = find_value(headers, USER_AGENT_REGEX) || user_agent_header
            headers[ACCEPT_ENCODING] = GZIP if use_compression?
            request_options.merge!(headers: headers)
          end

          def user_agent_header
            @user_agent_header ||= begin
              meta = ["RUBY_VERSION: #{JRUBY_VERSION}"]
              if RbConfig::CONFIG && RbConfig::CONFIG['host_os']
                meta << "#{RbConfig::CONFIG['host_os'].split('_').first[/[a-z]+/i].downcase} #{RbConfig::CONFIG['target_cpu']}"
              end
              meta << "Manticore #{::Manticore::VERSION}"
              "opensearch-ruby/#{VERSION} (#{meta.join('; ')})"
            end
          end
        end
      end
    end
  end
end
