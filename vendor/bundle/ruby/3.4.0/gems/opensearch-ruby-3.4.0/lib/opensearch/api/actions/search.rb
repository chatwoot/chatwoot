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
      # Returns results matching a query.
      #
      # @option arguments [List] :index A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices
      # @option arguments [String] :analyzer The analyzer to use for the query string
      # @option arguments [Boolean] :analyze_wildcard Specify whether wildcard and prefix queries should be analyzed (default: false)
      # @option arguments [Boolean] :ccs_minimize_roundtrips Indicates whether network round-trips should be minimized as part of cross-cluster search requests execution
      # @option arguments [String] :default_operator The default operator for query string query (AND or OR) (options: AND, OR)
      # @option arguments [String] :df The field to use as default where no field prefix is given in the query string
      # @option arguments [Boolean] :explain Specify whether to return detailed information about score computation as part of a hit
      # @option arguments [List] :stored_fields A comma-separated list of stored fields to return as part of a hit
      # @option arguments [List] :docvalue_fields A comma-separated list of fields to return as the docvalue representation of a field for each hit
      # @option arguments [Number] :from Starting offset (default: 0)
      # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option arguments [Boolean] :ignore_throttled Whether specified concrete, expanded or aliased indices should be ignored when throttled
      # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option arguments [Boolean] :lenient Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
      # @option arguments [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option arguments [String] :q Query in the Lucene query string syntax
      # @option arguments [List] :routing A comma-separated list of specific routing values
      # @option arguments [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @option arguments [String] :search_pipeline Customizable sequence of processing stages applied to search queries.
      # @option arguments [String] :search_type Search operation type (options: query_then_fetch, dfs_query_then_fetch)
      # @option arguments [Number] :size Number of hits to return (default: 10)
      # @option arguments [List] :sort A comma-separated list of <field>:<direction> pairs
      # @option arguments [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option arguments [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option arguments [List] :_source_includes A list of fields to extract and return from the _source field
      # @option arguments [Number] :terminate_after The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
      # @option arguments [List] :stats Specific 'tag' of the request for logging and statistical purposes
      # @option arguments [String] :suggest_field Specify which field to use for suggestions
      # @option arguments [String] :suggest_mode Specify suggest mode (options: missing, popular, always)
      # @option arguments [Number] :suggest_size How many suggestions to return in response
      # @option arguments [String] :suggest_text The source text for which the suggestions should be returned
      # @option arguments [Time] :timeout Explicit operation timeout
      # @option arguments [Boolean] :track_scores Whether to calculate and return scores even if they are not used for sorting
      # @option arguments [Boolean] :track_total_hits Indicate if the number of documents that match the query should be tracked
      # @option arguments [Boolean] :allow_partial_search_results Indicate if an error should be returned if there is a partial search failure or timeout
      # @option arguments [Boolean] :typed_keys Specify whether aggregation and suggester names should be prefixed by their respective types in the response
      # @option arguments [Boolean] :version Specify whether to return document version as part of a hit
      # @option arguments [Boolean] :seq_no_primary_term Specify whether to return sequence number and primary term of the last modification of each hit
      # @option arguments [Boolean] :request_cache Specify if request cache should be used for this request or not, defaults to index level setting
      # @option arguments [Number] :batched_reduce_size The number of shard results that should be reduced at once on the coordinating node. This value should be used as a protection mechanism to reduce the memory overhead per search request if the potential number of shards in the request can be large.
      # @option arguments [Number] :max_concurrent_shard_requests The number of concurrent shard requests per node this search executes concurrently. This value should be used to limit the impact of the search on the cluster in order to limit the number of concurrent shard requests
      # @option arguments [Number] :pre_filter_shard_size A threshold that enforces a pre-filter roundtrip to prefilter search shards based on query rewriting if the number of shards the search request expands to exceeds the threshold. This filter roundtrip can limit the number of shards significantly if for instance a shard can not match any documents based on its rewrite method ie. if date filters are mandatory to match but the shard bounds and the query are disjoint.
      # @option arguments [Boolean] :rest_total_hits_as_int Indicates whether hits.total should be rendered as an integer or an object in the rest search response
      # @option arguments [String] :min_compatible_shard_node The minimum compatible version that all shards involved in search should have for this request to be successful
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The search definition using the Query DSL
      #
      # *Deprecation notice*:
      # Specifying types in urls has been deprecated
      # Deprecated since version 7.0.0
      #
      #
      #
      def search(arguments = {})
        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _index = arguments.delete(:index)

        method = if arguments[:body]
                   OpenSearch::API::HTTP_POST
                 else
                   OpenSearch::API::HTTP_GET
                 end

        path = if _index
                 "#{Utils.__listify(_index)}/_search"
               else
                 '_search'
               end
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = arguments[:body]
        perform_request(method, path, params, body, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:search, %i[
        analyzer
        analyze_wildcard
        ccs_minimize_roundtrips
        default_operator
        df
        explain
        stored_fields
        docvalue_fields
        from
        ignore_unavailable
        ignore_throttled
        allow_no_indices
        expand_wildcards
        lenient
        preference
        q
        routing
        scroll
        search_pipeline
        search_type
        size
        sort
        _source
        _source_excludes
        _source_includes
        terminate_after
        stats
        suggest_field
        suggest_mode
        suggest_size
        suggest_text
        timeout
        track_scores
        track_total_hits
        allow_partial_search_results
        typed_keys
        version
        seq_no_primary_term
        request_cache
        batched_reduce_size
        max_concurrent_shard_requests
        pre_filter_shard_size
        rest_total_hits_as_int
        min_compatible_shard_node
      ].freeze)
    end
  end
end
