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
      # Allows to execute several search operations in one request.
      #
      # @option arguments [List] :index A comma-separated list of index names to use as default
      # @option arguments [String] :search_type Search operation type (options: query_then_fetch, dfs_query_then_fetch)
      # @option arguments [Number] :max_concurrent_searches Controls the maximum number of concurrent searches the multi search api will execute
      # @option arguments [Boolean] :typed_keys Specify whether aggregation and suggester names should be prefixed by their respective types in the response
      # @option arguments [Number] :pre_filter_shard_size A threshold that enforces a pre-filter roundtrip to prefilter search shards based on query rewriting if the number of shards the search request expands to exceeds the threshold. This filter roundtrip can limit the number of shards significantly if for instance a shard can not match any documents based on its rewrite method ie. if date filters are mandatory to match but the shard bounds and the query are disjoint.
      # @option arguments [Number] :max_concurrent_shard_requests The number of concurrent shard requests each sub search executes concurrently per node. This value should be used to limit the impact of the search on the cluster in order to limit the number of concurrent shard requests
      # @option arguments [Boolean] :rest_total_hits_as_int Indicates whether hits.total should be rendered as an integer or an object in the rest search response
      # @option arguments [Boolean] :ccs_minimize_roundtrips Indicates whether network round-trips should be minimized as part of cross-cluster search requests execution
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The request definitions (metadata-search request definition pairs), separated by newlines (*Required*)
      #
      # *Deprecation notice*:
      # Specifying types in urls has been deprecated
      # Deprecated since version 7.0.0
      #
      #
      #
      def msearch(arguments = {})
        raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _index = arguments.delete(:index)

        method = OpenSearch::API::HTTP_POST
        path   = if _index
                   "#{Utils.__listify(_index)}/_msearch"
                 else
                   '_msearch'
                 end
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = arguments[:body]
        if body.is_a?(Array) && body.any? { |d| d.key? :search }
          payload = body
                    .each_with_object([]) do |item, sum|
                      meta = item
                      data = meta.delete(:search)

                      sum << meta
                      sum << data
                    end
          payload = payload.map { |item| OpenSearch::API.serializer.dump(item) }
          payload << '' unless payload.empty?
          payload = payload.join("\n")
        elsif body.is_a?(Array)
          payload = body.map { |d| d.is_a?(String) ? d : OpenSearch::API.serializer.dump(d) }
          payload << '' unless payload.empty?
          payload = payload.join("\n")
        else
          payload = body
        end

        headers.merge!('Content-Type' => 'application/x-ndjson')
        perform_request(method, path, params, payload, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:msearch, %i[
        search_type
        max_concurrent_searches
        typed_keys
        pre_filter_shard_size
        max_concurrent_shard_requests
        rest_total_hits_as_int
        ccs_minimize_roundtrips
      ].freeze)
    end
  end
end
