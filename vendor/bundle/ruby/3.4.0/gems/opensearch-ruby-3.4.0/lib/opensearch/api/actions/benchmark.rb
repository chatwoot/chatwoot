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
  module API
    module Actions
      # Run a single query, or a set of queries, and return statistics on their performance
      #
      # @example Return statistics for a single query
      #
      #     client.benchmark body: {
      #       name: 'my_benchmark',
      #       competitors: [
      #         {
      #           name: 'query_1',
      #           requests: [
      #             { query: { match: { _all: 'a*' } } }
      #           ]
      #         }
      #       ]
      #     }
      #
      # @example Return statistics for a set of "competing" queries
      #
      #     client.benchmark body: {
      #       name: 'my_benchmark',
      #       competitors: [
      #         {
      #           name: 'query_a',
      #           requests: [
      #             { query: { match: { _all: 'a*' } } }
      #           ]
      #         },
      #         {
      #           name: 'query_b',
      #           requests: [
      #             { query: { match: { _all: 'b*' } } }
      #           ]
      #         }
      #       ]
      #     }
      #
      # @option arguments [List] :index A comma-separated list of index names; use `_all` or empty string
      #                                 to perform the operation on all indices
      # @option arguments [Hash] :body The search definition using the Query DSL
      # @option arguments [Boolean] :verbose Specify whether to return verbose statistics about each iteration
      #                                      (default: false)
      #
      #
      def benchmark(arguments = {})
        method = HTTP_PUT
        path   = '_bench'
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
        body   = arguments[:body]

        perform_request(method, path, params, body).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.1.1
      ParamsRegistry.register(:benchmark, [:verbose].freeze)
    end
  end
end
