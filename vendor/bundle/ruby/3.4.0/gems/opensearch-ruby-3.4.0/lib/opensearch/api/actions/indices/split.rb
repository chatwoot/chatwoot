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
        # Allows you to split an existing index into a new index with more primary shards.
        #
        # @option arguments [String] :index The name of the source index to split
        # @option arguments [String] :target The name of the target index to split into
        # @option arguments [Boolean] :copy_settings whether or not to copy settings from the source index (defaults to false)
        # @option arguments [Time] :timeout Explicit operation timeout
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Specify timeout for connection to master
        # @option arguments [Time] :cluster_manager_timeout Specify timeout for connection to cluster_manager
        # @option arguments [String] :wait_for_active_shards Set the number of active shards to wait for on the shrunken index before the operation returns.
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [Hash] :body The configuration for the target index (`settings` and `aliases`)
        #
        #
        def split(arguments = {})
          raise ArgumentError, "Required argument 'index' missing" unless arguments[:index]
          raise ArgumentError, "Required argument 'target' missing" unless arguments[:target]

          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _index = arguments.delete(:index)

          _target = arguments.delete(:target)

          method = OpenSearch::API::HTTP_PUT
          path   = "#{Utils.__listify(_index)}/_split/#{Utils.__listify(_target)}"
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:split, %i[
          copy_settings
          timeout
          master_timeout
          cluster_manager_timeout
          wait_for_active_shards
        ].freeze)
      end
    end
  end
end
