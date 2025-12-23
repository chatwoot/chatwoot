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
        # Simulate resolving the given template name or body
        #
        # @option arguments [String] :name The name of the index template
        # @option arguments [Boolean] :create Whether the index template we optionally defined in the body should only be dry-run added if new or can also replace an existing one
        # @option arguments [String] :cause User defined reason for dry-run creating the new template for simulation purposes
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Specify timeout for connection to master
        # @option arguments [Time] :cluster_manager_timeout Specify timeout for connection to cluster_manager
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [Hash] :body New index template definition to be simulated, if no index template name is specified
        #
        #
        def simulate_template(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _name = arguments.delete(:name)

          method = OpenSearch::API::HTTP_POST
          path   = if _name
                     "_index_template/_simulate/#{Utils.__listify(_name)}"
                   else
                     '_index_template/_simulate'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:simulate_template, %i[
          create
          cause
          master_timeout
          cluster_manager_timeout
        ].freeze)
      end
    end
  end
end
