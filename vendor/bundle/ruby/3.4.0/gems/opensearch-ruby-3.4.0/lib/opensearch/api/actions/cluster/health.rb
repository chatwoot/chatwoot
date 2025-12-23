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
        # Returns basic information about the health of the cluster.
        #
        # @option arguments [List] :index Limit the information returned to a specific index
        # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
        # @option arguments [String] :level Specify the level of detail for returned information (options: cluster, indices, shards)
        # @option arguments [Boolean] :local Return local information, do not retrieve the state from cluster_manager node (default: false)
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Explicit operation timeout for connection to master node
        # @option arguments [Time] :cluster_manager_timeout Explicit operation timeout for connection to cluster_manager node
        # @option arguments [Time] :timeout Explicit operation timeout
        # @option arguments [String] :wait_for_active_shards Wait until the specified number of shards is active
        # @option arguments [String] :wait_for_nodes Wait until the specified number of nodes is available
        # @option arguments [String] :wait_for_events Wait until all currently queued events with the given priority are processed (options: immediate, urgent, high, normal, low, languid)
        # @option arguments [Boolean] :wait_for_no_relocating_shards Whether to wait until there are no relocating shards in the cluster
        # @option arguments [Boolean] :wait_for_no_initializing_shards Whether to wait until there are no initializing shards in the cluster
        # @option arguments [String] :wait_for_status Wait until cluster is in a specific state (options: green, yellow, red)
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def health(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _index = arguments.delete(:index)

          method = OpenSearch::API::HTTP_GET
          path   = if _index
                     "_cluster/health/#{Utils.__listify(_index)}"
                   else
                     '_cluster/health'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:health, %i[
          expand_wildcards
          level
          local
          master_timeout
          cluster_manager_timeout
          timeout
          wait_for_active_shards
          wait_for_nodes
          wait_for_events
          wait_for_no_relocating_shards
          wait_for_no_initializing_shards
          wait_for_status
        ].freeze)
      end
    end
  end
end
