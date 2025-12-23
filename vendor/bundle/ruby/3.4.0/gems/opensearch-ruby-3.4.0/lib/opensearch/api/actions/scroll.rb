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
      # Allows to retrieve a large numbers of results from a single search request.
      #
      # @option arguments [String] :scroll_id The scroll ID *Deprecated*
      # @option arguments [Time] :scroll Specify how long a consistent view of the index should be maintained for scrolled search
      # @option arguments [Boolean] :rest_total_hits_as_int Indicates whether hits.total should be rendered as an integer or an object in the rest search response
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body The scroll ID if not passed by URL or query parameter.
      #
      # *Deprecation notice*:
      # A scroll id can be quite large and should be specified as part of the body
      # Deprecated since version 7.0.0
      #
      #
      #
      def scroll(arguments = {})
        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _scroll_id = arguments.delete(:scroll_id)

        method = if arguments[:body]
                   OpenSearch::API::HTTP_POST
                 else
                   OpenSearch::API::HTTP_GET
                 end

        path = if _scroll_id
                 "_search/scroll/#{Utils.__listify(_scroll_id)}"
               else
                 '_search/scroll'
               end
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)

        body = arguments[:body]
        perform_request(method, path, params, body, headers).body
      end

      # Register this action with its valid params when the module is loaded.
      #
      # @since 6.2.0
      ParamsRegistry.register(:scroll, %i[
        scroll
        scroll_id
        rest_total_hits_as_int
      ].freeze)
    end
  end
end
