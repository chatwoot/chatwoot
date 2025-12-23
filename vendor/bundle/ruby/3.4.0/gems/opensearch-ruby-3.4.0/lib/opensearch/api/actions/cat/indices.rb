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
    module Cat
      module Actions
        # Returns information about indices: number of primaries and replicas, document counts, disk size, ...
        #
        # @option arguments [List] :index A comma-separated list of index names to limit the returned information
        # @option arguments [String] :format a short version of the Accept header, e.g. json, yaml
        # @option arguments [String] :bytes The unit in which to display byte values (options: b, k, kb, m, mb, g, gb, t, tb, p, pb)
        # @option arguments [Boolean] :local Return local information, do not retrieve the state from cluster_manager node (default: false)
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Explicit operation timeout for connection to master node
        # @option arguments [Time] :cluster_manager_timeout Explicit operation timeout for connection to cluster_manager node
        # @option arguments [List] :h Comma-separated list of column names to display
        # @option arguments [String] :health A health status ("green", "yellow", or "red" to filter only indices matching the specified health status (options: green, yellow, red)
        # @option arguments [Boolean] :help Return help information
        # @option arguments [Boolean] :pri Set to true to return stats only for primary shards
        # @option arguments [List] :s Comma-separated list of column names or column aliases to sort by
        # @option arguments [String] :time The unit in which to display time values (options: d, h, m, s, ms, micros, nanos)
        # @option arguments [Boolean] :v Verbose mode. Display column headers
        # @option arguments [Boolean] :include_unloaded_segments If set to true segment stats will include stats for segments that are not currently loaded into memory
        # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def indices(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _index = arguments.delete(:index)

          method = OpenSearch::API::HTTP_GET
          path   = if _index
                     "_cat/indices/#{Utils.__listify(_index)}"
                   else
                     '_cat/indices'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
          params[:h] = Utils.__listify(params[:h]) if params[:h]

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:indices, %i[
          format
          bytes
          local
          master_timeout
          cluster_manager_timeout
          h
          health
          help
          pri
          s
          time
          v
          include_unloaded_segments
          expand_wildcards
        ].freeze)
      end
    end
  end
end
