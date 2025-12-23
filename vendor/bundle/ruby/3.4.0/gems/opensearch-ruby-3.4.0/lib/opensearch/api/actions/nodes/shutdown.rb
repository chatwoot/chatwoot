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
    module Nodes
      module Actions
        # Shutdown one or all nodes
        #
        # @example Shut down node named _Bloke_
        #
        #     client.nodes.shutdown node_id: 'Bloke'
        #
        # @option arguments [List] :node_id A comma-separated list of node IDs or names to perform the operation on; use
        #                                   `_local` to shutdown the node you're connected to, leave empty to
        #                                   shutdown all nodes
        # @option arguments [Time] :delay Set the delay for the operation (default: 1s)
        # @option arguments [Boolean] :exit Exit the JVM as well (default: true)
        #
        # @see http://opensearch.org/guide/reference/api/admin-cluster-nodes-shutdown/
        #
        def shutdown(arguments = {})
          method = HTTP_POST
          path   = Utils.__pathify '_cluster/nodes', Utils.__listify(arguments[:node_id]), '_shutdown'

          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
          body   = nil

          perform_request(method, path, params, body).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.1.1
        ParamsRegistry.register(:shutdown, %i[
          delay
          exit
        ].freeze)
      end
    end
  end
end
