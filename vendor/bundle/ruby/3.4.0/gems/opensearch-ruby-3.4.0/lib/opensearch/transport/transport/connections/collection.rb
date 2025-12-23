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
      module Connections
        # Wraps the collection of connections for the transport object as an Enumerable object.
        #
        # @see Base#connections
        # @see Selector::Base#select
        # @see Connection
        #
        class Collection
          include Enumerable

          DEFAULT_SELECTOR = Selector::RoundRobin

          attr_reader :selector

          # @option arguments [Array]    :connections    An array of {Connection} objects.
          # @option arguments [Constant] :selector_class The class to be used as a connection selector strategy.
          # @option arguments [Object]   :selector       The selector strategy object.
          #
          def initialize(arguments = {})
            selector_class = arguments[:selector_class] || DEFAULT_SELECTOR
            @connections   = arguments[:connections]    || []
            @selector      = arguments[:selector]       || selector_class.new(arguments.merge(connections: self))
          end

          # Returns an Array of hosts information in this collection as Hashes.
          #
          # @return [Array]
          #
          def hosts
            @connections.to_a.map(&:host)
          end

          # Returns an Array of alive connections.
          #
          # @return [Array]
          #
          def connections
            @connections.reject(&:dead?)
          end
          alias alive connections

          # Returns an Array of dead connections.
          #
          # @return [Array]
          #
          def dead
            @connections.select(&:dead?)
          end

          # Returns an Array of all connections, both dead and alive
          #
          # @return [Array]
          #
          def all
            @connections
          end

          # Returns a connection.
          #
          # If there are no alive connections, returns a connection with least failures.
          # Delegates to selector's `#select` method to get the connection.
          #
          # @return [Connection]
          #
          def get_connection(options = {})
            selector.select(options) || @connections.min_by(&:failures)
          end

          def each(&block)
            connections.each(&block)
          end

          def slice(*args)
            connections.slice(*args)
          end
          alias [] slice

          def size
            connections.size
          end

          # Add connection(s) to the collection
          #
          # @param connections [Connection,Array] A connection or an array of connections to add
          # @return [self]
          #
          def add(connections)
            @connections += Array(connections).to_a
            self
          end

          # Remove connection(s) from the collection
          #
          # @param connections [Connection,Array] A connection or an array of connections to remove
          # @return [self]
          #
          def remove(connections)
            @connections -= Array(connections).to_a
            self
          end
        end
      end
    end
  end
end
