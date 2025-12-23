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
    module Indices
      module Actions
        # Provides statistics on operations happening in an index.
        #
        # @option arguments [List] :metric Limit the information returned the specific metrics. (options: _all, completion, docs, fielddata, query_cache, flush, get, indexing, merge, request_cache, refresh, search, segments, store, warmer, suggest)
        # @option arguments [List] :index A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
        # @option arguments [List] :completion_fields A comma-separated list of fields for `fielddata` and `suggest` index metric (supports wildcards)
        # @option arguments [List] :fielddata_fields A comma-separated list of fields for `fielddata` index metric (supports wildcards)
        # @option arguments [List] :fields A comma-separated list of fields for `fielddata` and `completion` index metric (supports wildcards)
        # @option arguments [List] :groups A comma-separated list of search groups for `search` index metric
        # @option arguments [String] :level Return stats aggregated at cluster, index or shard level (options: cluster, indices, shards)
        # @option arguments [List] :types A comma-separated list of document types for the `indexing` index metric
        # @option arguments [Boolean] :include_segment_file_sizes Whether to report the aggregated disk usage of each one of the Lucene index files (only applies if segment stats are requested)
        # @option arguments [Boolean] :include_unloaded_segments If set to true segment stats will include stats for segments that are not currently loaded into memory
        # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
        # @option arguments [Boolean] :forbid_closed_indices If set to false stats will also collected from closed indices if explicitly specified or if expand_wildcards expands to closed indices
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def stats(arguments = {})
          headers = arguments.delete(:headers) || {}

          method = HTTP_GET
          parts  = Utils.__extract_parts arguments, ParamsRegistry.get(:stats_parts)
          path   = Utils.__pathify Utils.__listify(arguments[:index]), '_stats', Utils.__listify(parts)
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(:stats_params)
          params[:fields] = Utils.__listify(params[:fields], escape: false) if params[:fields]
          params[:groups] = Utils.__listify(params[:groups], escape: false) if params[:groups]

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:stats_params, %i[
          completion_fields
          fielddata_fields
          fields
          groups
          level
          types
          include_segment_file_sizes
          include_unloaded_segments
          expand_wildcards
          forbid_closed_indices
        ].freeze)

        ParamsRegistry.register(:stats_parts, %i[
          _all
          completion
          docs
          fielddata
          query_cache
          flush
          get
          indexing
          merge
          request_cache
          refresh
          search
          segments
          store
          warmer
          suggest
          metric
        ].freeze)
      end
    end
  end
end
