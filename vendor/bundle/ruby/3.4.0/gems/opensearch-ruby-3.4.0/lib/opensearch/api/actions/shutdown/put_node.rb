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
    module Shutdown
      module Actions
        # Adds a node to be shut down
        # This functionality is Experimental and may be changed or removed
        # completely in a future release. OpenSearch will take a best effort approach
        # to fix any issues, but experimental features are not subject to the
        # support SLA of official GA features.
        #
        # @option arguments [String] :node_id The node id of node to be shut down
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [Hash] :body The shutdown type definition to register (*Required*)
        #
        #
        def put_node(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]
          raise ArgumentError, "Required argument 'node_id' missing" unless arguments[:node_id]

          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _node_id = arguments.delete(:node_id)

          method = OpenSearch::API::HTTP_PUT
          path   = "_nodes/#{Utils.__listify(_node_id)}/shutdown"
          params = {}

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end
      end
    end
  end
end
