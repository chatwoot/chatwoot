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
    module Tasks
      module Actions
        # Cancels a task, if it can be cancelled through an API.
        # This functionality is Experimental and may be changed or removed
        # completely in a future release. OpenSearch will take a best effort approach
        # to fix any issues, but experimental features are not subject to the
        # support SLA of official GA features.
        #
        # @option arguments [String] :task_id Cancel the task with specified task id (node_id:task_number)
        # @option arguments [List] :nodes A comma-separated list of node IDs or names to limit the returned information; use `_local` to return information from the node you're connecting to, leave empty to get information from all nodes
        # @option arguments [List] :actions A comma-separated list of actions that should be cancelled. Leave empty to cancel all.
        # @option arguments [String] :parent_task_id Cancel tasks with specified parent task id (node_id:task_number). Set to -1 to cancel all.
        # @option arguments [Boolean] :wait_for_completion Should the request block until the cancellation of the task and its descendant tasks is completed. Defaults to false
        # @option arguments [Hash] :headers Custom HTTP headers
        #
        #
        def cancel(arguments = {})
          headers = arguments.delete(:headers) || {}

          arguments = arguments.clone

          _task_id = arguments.delete(:task_id)

          method = OpenSearch::API::HTTP_POST
          path   = if _task_id
                     "_tasks/#{Utils.__listify(_task_id)}/_cancel"
                   else
                     '_tasks/_cancel'
                   end
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

          body = nil
          perform_request(method, path, params, body, headers).body
        end

        # Register this action with its valid params when the module is loaded.
        #
        # @since 6.2.0
        ParamsRegistry.register(:cancel, %i[
          nodes
          actions
          parent_task_id
          wait_for_completion
        ].freeze)
      end
    end
  end
end
