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
        # A query which wraps another query or filter and returns a constant score for matching documents
        #
        # @example
        #
        #     search do
        #       query do
        #         constant_score do
        #           query do
        #             match content: 'Twitter'
        #           end
        #         end
        #       end
        #     end
        #
        # @see http://opensearch.org/guide/en/opensearch/guide/current/ignoring-tfidf.html
        #
        class ConstantScore
          include BaseComponent

          option_method :boost

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
            hash
          end
        end
      end
    end
  end
end
