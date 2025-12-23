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
        module ParamsRegistry
          extend self

          # A Mapping of all the actions to their list of valid params.
          #
          # @since 6.1.1
          PARAMS = {}

          # Register an action with its list of valid params.
          #
          # @example Register the action.
          #   ParamsRegistry.register(:benchmark, [ :verbose ])
          #
          # @param [ Symbol ] action The action to register.
          # @param [ Array[Symbol] ] valid_params The list of valid params.
          #
          # @since 6.1.1
          def register(action, valid_params)
            PARAMS[action.to_sym] = valid_params
          end

          # Get the list of valid params for a given action.
          #
          # @example Get the list of valid params.
          #   ParamsRegistry.get(:benchmark)
          #
          # @param [ Symbol ] action The action.
          #
          # @return [ Array<Symbol> ] The list of valid params for the action.
          #
          # @since 6.1.1
          def get(action)
            PARAMS.fetch(action, [])
          end
        end
      end
    end
  end
end
