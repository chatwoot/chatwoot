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
      # Explicitly clears the search context for a scroll.
      #
      # @option arguments [List] :scroll_id A comma-separated list of scroll IDs to clear *Deprecated*
      # @option arguments [Hash] :headers Custom HTTP headers
      # @option arguments [Hash] :body A comma-separated list of scroll IDs to clear if none was specified via the scroll_id parameter
      #
      # *Deprecation notice*:
      # A scroll id can be quite large and should be specified as part of the body
      # Deprecated since version 7.0.0
      #
      #
      #
      def clear_scroll(arguments = {})
        headers = arguments.delete(:headers) || {}

        arguments = arguments.clone

        _scroll_id = arguments.delete(:scroll_id)

        method = OpenSearch::API::HTTP_DELETE
        path   = if _scroll_id
                   "_search/scroll/#{Utils.__listify(_scroll_id)}"
                 else
                   '_search/scroll'
                 end
        params = {}

        body = arguments[:body]
        perform_request(method, path, params, body, headers).body
      end
    end
  end
end
