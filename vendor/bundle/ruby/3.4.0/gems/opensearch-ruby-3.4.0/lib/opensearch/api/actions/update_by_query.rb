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
      # Performs an update on every document in the index without changing the source,
      # for example to pick up a mapping change.
      #
      # @option arguments [List] :index A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices (*Required*)
      # @option arguments [String] :analyzer The analyzer to use for the query string
      # @option arguments [Boolean] :analyze_wildcard Specify whether wildcard and prefix queries should be analyzed (default: false)
      # @option arguments [String] :default_operator The default operator for query string query (AND or OR) (options: AND, OR)
      # @option arguments [String] :df The field to use as default where no field prefix is given in the query string
      # @option arguments [Number] :from Starting offset (default: 0)
      # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option arguments [String] :conflicts What to do when the update by query hits version conflicts? (options: abort, proceed)
      # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option arguments [Boolean] :lenient Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
      # @option arguments [String] :pipeline Ingest pipeline to set on index requests made by this action. (default: none)
      # @option arguments [String] :preference Specify the node or shard the operation should be performed on (default: random)
      # @option arguments [String] :q Query in the Lucene query string syntax
      # @option arguments [List] :routing A comma-separated list of specific routing values
      # @option arguments [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @option arguments [String] :search_type Search operation type (options: query_then_fetch, dfs_query_then_fetch)
      # @option arguments [Time] :search_timeout Explicit timeout for each search request. Defaults to no timeout.
      # @option arguments [Number] :size Deprecated, please use `max_docs` instead
      # @option arguments [Number] :max_docs Maximum number of documents to process (default: all documents)
      # @option arguments [List] :sort A comma-separated list of <field>:<direction> pairs
      # @option arguments [List] :_source True or false to return the _source field or not, or a list of fields to return
      # @option arguments [List] :_source_excludes A list of fields to exclude from the returned _source field
      # @option arguments [List] :_source_includes A list of fields to extract and return from the _source field
      # @option arguments [Number] :terminate_after The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
      # @option arguments [List] :stats Specific 'tag' of the request for logging and statistical purposes
      # @option arguments [Boolean] :version Specify whether to return document version as part of a hit
      # @option arguments [Boolean] :version_type Should the document increment the version number (internal) on hit or not (reindex)
      # @option arguments [Boolean] :request_cache Specify if request cache should be used for this request or not, defaults to index level setting
      # @option arguments [Boolean] :refresh Should the affected indexes be refreshed?
      # @option arguments [Time] :timeout Time each individual bulk request should wait for shards that are unavailable.
      # @option arguments [String] :wait_for_active_shards Sets the number of shard copies that must be active before proceeding with the update by query operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
      # @option arguments [Number] :scroll_size Size on the scroll request powering the update by query
      # @option arguments [Boolean] :wait_for_completion Should the request should block until the update by query operation is complete.
      # @option arguments [Number] :requests_per_second The throttle to set on this request in sub-requests per second. -1 means no throttle.
      # @option arguments [Number|string] :slices The number of slices this task should be divided into. Defaults to 1, meaning the task isn't sliced into subtasks. Can be set to `auto`.
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The search definition using the Query DSL
      #
      # *Deprecation notice*:
      # Specifying types in urls has been deprecated
      # Deprecated since version 7.0.0
      #
      #
      #
      def update_by_query(arguments = {})
        raise ArgumentError, "Required argument 'index' missing" unless arguments[:index]

        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _index = arguments.delete(:index)

        method = OpenSearch::API::HTTP_POST
        path   = "#{Utils.__listify(_index)}/_update_by_query"
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = arguments[:body]
        perform_request(method, path, params, body, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:update_by_query, %i[
        analyzer
        analyze_wildcard
        default_operator
        df
        from
        ignore_unavailable
        allow_no_indices
        conflicts
        expand_wildcards
        lenient
        pipeline
        preference
        q
        routing
        scroll
        search_type
        search_timeout
        size
        max_docs
        sort
        _source
        _source_excludes
        _source_includes
        terminate_after
        stats
        version
        version_type
        request_cache
        refresh
        timeout
        wait_for_active_shards
        scroll_size
        wait_for_completion
        requests_per_second
        slices
      ].freeze)
    end
  end
end
