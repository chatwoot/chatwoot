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
        module Selector
          # @abstract Common functionality for connection selector implementations.
          #
          module Base
            attr_reader :connections

            # @option arguments [Connections::Collection] :connections Collection with connections.
            #
            def initialize(arguments = {})
              @connections = arguments[:connections]
            end

            # @abstract Selector strategies implement this method to
            #           select and return a connection from the pool.
            #
            # @return [Connection]
            #
            def select(_options = {})
              raise NoMethodError, "Implement this method in the selector implementation."
            end
          end

          # "Random connection" selector strategy.
          #
          class Random
            include Base

            # Returns a random connection from the collection.
            #
            # @return [Connections::Connection]
            #
            def select(_options = {})
              connections.to_a.send(defined?(RUBY_VERSION) && RUBY_VERSION > '1.9' ? :sample : :choice)
            end
          end

          # "Round-robin" selector strategy (default).
          #
          class RoundRobin
            include Base

            # @option arguments [Connections::Collection] :connections Collection with connections.
            #
            def initialize(arguments = {})
              super
              @mutex = Mutex.new
              @current = nil
            end

            # Returns the next connection from the collection, rotating them in round-robin fashion.
            #
            # @return [Connections::Connection]
            #
            def select(_options = {})
              @mutex.synchronize do
                conns = connections
                if @current && (@current < conns.size - 1)
                  @current += 1
                else
                  @current = 0
                end
                conns[@current]
              end
            end
          end
        end
      end
    end
  end
end
