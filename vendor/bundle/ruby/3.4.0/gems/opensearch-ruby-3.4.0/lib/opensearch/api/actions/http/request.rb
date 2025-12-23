# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.

# This code was generated from OpenSearch API Spec.
# Update the code generation logic instead of modifying this file directly.

# frozen_string_literal: true

module OpenSearch
  module API
    module Http
      module Actions
        private

        def request(method, url, headers: {}, body: nil, params: {})
          body = OpenSearch::API::Utils.__bulkify(body) if body.is_a?(Array)
          headers.merge!('Content-Type' => 'application/x-ndjson') if body.is_a?(Array)

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
