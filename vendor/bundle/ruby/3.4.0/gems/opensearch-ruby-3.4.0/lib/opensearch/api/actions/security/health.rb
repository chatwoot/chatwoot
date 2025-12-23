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
    module Security
      module Actions
        HEALTH_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Checks to see if the Security plugin is up and running.
        #
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#health-check]
        def health(arguments = {})
          arguments = arguments.clone
          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'health'
          method  = OpenSearch::API::HTTP_GET
          params  = Utils.__validate_and_extract_params arguments, HEALTH_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
