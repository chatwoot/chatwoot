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
    module Snapshot
      module Actions
        # Deletes a snapshot.
        #
        # @option arguments [String] :repository A repository name
        # @option arguments [String] :snapshot A snapshot name
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Explicit operation timeout for connection to master node
        # @option arguments [Time] :cluster_manager_timeout Explicit operation timeout for connection to cluster_manager node
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def delete(arguments = {})
          raise ArgumentError, "Required argument 'repository' missing" unless arguments[:repository]
          raise ArgumentError, "Required argument 'snapshot' missing" unless arguments[:snapshot]

          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _repository = arguments.delete(:repository)

          _snapshot = arguments.delete(:snapshot)

          method = OpenSearch::API::HTTP_DELETE
          path   = "_snapshot/#{Utils.__listify(_repository)}/#{Utils.__listify(_snapshot)}"
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = nil
          if Array(arguments[:ignore]).include?(404)
            Utils.__rescue_from_not_found { perform_request(method, path, params, body, headers).body }
          else
            perform_request(method, path, params, body, headers).body
          end
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:delete, %i[
          master_timeout
          cluster_manager_timeout
        ].freeze)
      end
    end
  end
end
