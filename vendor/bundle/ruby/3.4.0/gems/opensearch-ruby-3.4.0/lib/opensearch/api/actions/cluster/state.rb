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
    module Cluster
      module Actions
        # Returns a comprehensive information about the state of the cluster.
        #
        # @option arguments [List] :metric Limit the information returned to the specified metrics (options: _all, blocks, metadata, nodes, routing_table, routing_nodes, master_node, version)
        # @option arguments [List] :index A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
        # @option arguments [Boolean] :local Return local information, do not retrieve the state from cluster_manager node (default: false)
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Specify timeout for connection to master
        # @option arguments [Time] :cluster_manager_timeout Specify timeout for connection to cluster_manager
        # @option arguments [Boolean] :flat_settings Return settings in flat format (default: false)
        # @option arguments [Number] :wait_for_metadata_version Wait for the metadata version to be equal or greater than the specified metadata version
        # @option arguments [Time] :wait_for_timeout The maximum time to wait for wait_for_metadata_version before timing out
        # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
        # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
        # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def state(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _metric = arguments.delete(:metric)

          _index = arguments.delete(:index)

          method = OpenSearch::API::HTTP_GET
          path   = if _metric && _index
                     "_cluster/state/#{Utils.__listify(_metric)}/#{Utils.__listify(_index)}"
                   elsif _metric
                     "_cluster/state/#{Utils.__listify(_metric)}"
                   else
                     '_cluster/state'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:state, %i[
          local
          master_timeout
          cluster_manager_timeout
          flat_settings
          wait_for_metadata_version
          wait_for_timeout
          ignore_unavailable
          allow_no_indices
          expand_wildcards
        ].freeze)
      end
    end
  end
end
