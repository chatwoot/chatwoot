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
      # Handles node discovery ("sniffing")
      #
      class Sniffer
        PROTOCOL = 'http'

        attr_reader   :transport
        attr_accessor :timeout

        # @param transport [Object] A transport instance
        #
        def initialize(transport)
          @transport = transport
          @timeout   = transport.options[:sniffer_timeout] || 1
        end

        # Retrieves the node list from the OpenSearch's
        # _Nodes Info API_
        # and returns a normalized Array of information suitable for passing to transport.
        #
        # Shuffles the collection before returning it when the `randomize_hosts` option is set for transport.
        #
        # @return [Array<Hash>]
        # @raise  [SnifferTimeoutError]
        #
        def hosts
          Timeout.timeout(timeout, SnifferTimeoutError) do
            nodes = perform_sniff_request.body

            hosts = nodes['nodes'].map do |id, info|
              next unless info[PROTOCOL]
              host, port = parse_publish_address(info[PROTOCOL]['publish_address'])

              {
                id: id,
                name: info['name'],
                version: info['version'],
                host: host,
                port: port,
                roles: info['roles'],
                attributes: info['attributes']
              }
            end.compact

            hosts.shuffle! if transport.options[:randomize_hosts]
            hosts
          end
        end

        private

        def perform_sniff_request
          transport.perform_request(
            'GET', '_nodes/http', {}, nil, nil,
            reload_on_failure: false
          )
        end

        def parse_publish_address(publish_address)
          # publish_address is in the format hostname/ip:port
          if publish_address =~ %r{/}
            parts = publish_address.partition('/')
            [parts[0], parse_address_port(parts[2])[1]]
          else
            parse_address_port(publish_address)
          end
        end

        def parse_address_port(publish_address)
          # address is ipv6
          if publish_address =~ /[\[\]]/
            if (parts = publish_address.match(/\A\[(.+)\](?::(\d+))?\z/))
              [parts[1], parts[2]]
            end
          else
            publish_address.split(':')
          end
        end
      end
    end
  end
end
