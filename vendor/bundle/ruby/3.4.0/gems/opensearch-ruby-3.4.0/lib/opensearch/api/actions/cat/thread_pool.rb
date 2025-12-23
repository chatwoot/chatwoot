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
        # Returns cluster-wide thread pool statistics per node.
        # By default the active, queue and rejected statistics are returned for all thread pools.
        #
        # @option arguments [List] :thread_pool_patterns A comma-separated list of regular-expressions to filter the thread pools in the output
        # @option arguments [String] :format a short version of the Accept header, e.g. json, yaml
        # @option arguments [String] :size The multiplier in which to display values *Deprecated* (options: , k, m, g, t, p)
        # @option arguments [Boolean] :local Return local information, do not retrieve the state from cluster_manager node (default: false)
        # @option arguments [Time] :master_timeout (DEPRECATED: use cluster_manager_timeout instead) Explicit operation timeout for connection to master node
        # @option arguments [Time] :cluster_manager_timeout Explicit operation timeout for connection to cluster_manager node
        # @option arguments [List] :h Comma-separated list of column names to display
        # @option arguments [Boolean] :help Return help information
        # @option arguments [List] :s Comma-separated list of column names or column aliases to sort by
        # @option arguments [Boolean] :v Verbose mode. Display column headers
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def thread_pool(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _thread_pool_patterns = arguments.delete(:thread_pool_patterns)

          method = OpenSearch::API::HTTP_GET
          path   = if _thread_pool_patterns
                     "_cat/thread_pool/#{Utils.__listify(_thread_pool_patterns)}"
                   else
                     '_cat/thread_pool'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
          params[:h] = Utils.__listify(params[:h]) if params[:h]

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:thread_pool, %i[
          format
          size
          local
          master_timeout
          cluster_manager_timeout
          h
          help
          s
          v
        ].freeze)
      end
    end
  end
end
