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
  module DSL
    module Search
      module Queries
        # A query which allows to modify the score of documents matching the query,
        # either via built-in functions or a custom script
        #
        # @example Find documents with specific amenities, boosting documents within a certain
        #          price range and geogprahical location
        #
        #     search do
        #       query do
        #         function_score do
        #           filter do
        #             terms amenities: ['wifi', 'pets']
        #           end
        #           functions << { gauss: { price:    { origin: 100, scale: 200 } } }
        #           functions << { gauss: { location: { origin: '50.090223,14.399590', scale: '5km' } } }
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/guide/current/function-score-query.html
        #
        class FunctionScore
          include BaseComponent

          option_method :script_score
          option_method :boost
          option_method :max_boost
          option_method :score_mode
          option_method :boost_mode

          def initialize(*args, &block)
            super
            @functions = []
          end

          # DSL method for building the `query` part of the query definition
          #
          # @return [self]
          #
          def query(*args, &block)
            @query = block ? @query = Query.new(*args, &block) : args.first
            self
          end

          # DSL method for building the `filter` part of the query definition
          #
          # @return [self]
          #
          def filter(*args, &block)
            @filter = block ? Filter.new(*args, &block) : args.first
            self
          end

          # DSL method for building the `functions` part of the query definition
          #
          # @return [Array]
          #
          def functions(value = nil)
            if value
              @functions = value
            else
              @functions
            end
          end

          # Set the `functions` part of the query definition
          #
          # @return [Array]
          #
          attr_writer :functions

          # Converts the query definition to a Hash
          #
          # @return [Hash]
          #
          def to_hash
            hash = super
            if @query
              _query = @query.respond_to?(:to_hash) ? @query.to_hash : @query
              hash[name].update(query: _query)
            end
            if @filter
              _filter = @filter.respond_to?(:to_hash) ? @filter.to_hash : @filter
              hash[name].update(filter: _filter)
            end
            hash[name].update(functions: @functions) unless @functions.empty?
            hash
          end
        end
      end
    end
  end
end
