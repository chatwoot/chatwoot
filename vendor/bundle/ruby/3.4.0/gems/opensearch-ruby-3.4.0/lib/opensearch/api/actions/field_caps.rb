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
    module Actions
      # Returns the information about the capabilities of fields among multiple indices.
      #
      # @option arguments [List] :index A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
      # @option arguments [List] :fields A comma-separated list of field names
      # @option arguments [Boolean] :ignore_unavailable Whether specified concrete indices should be ignored when unavailable (missing or closed)
      # @option arguments [Boolean] :allow_no_indices Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
      # @option arguments [String] :expand_wildcards Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
      # @option arguments [Boolean] :include_unmapped Indicates whether unmapped fields should be included in the response.
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body An index filter specified with the Query DSL
      #
      #
      def field_caps(arguments = {})
        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _index = arguments.delete(:index)

        method = if arguments[:body]
                   OpenSearch::API::HTTP_POST
                 else
                   OpenSearch::API::HTTP_GET
                 end

        path = if _index
                 "#{Utils.__listify(_index)}/_field_caps"
               else
                 '_field_caps'
               end
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = arguments[:body]
        perform_request(method, path, params, body, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:field_caps, %i[
        fields
        ignore_unavailable
        allow_no_indices
        expand_wildcards
        include_unmapped
      ].freeze)
    end
  end
end
