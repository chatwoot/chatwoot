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
        GET_ROLE_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Retrieves one role.
        #
        # @option arguments [String] :role *Required*
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#get-role]
        def get_role(arguments = {})
          raise ArgumentError, "Required argument 'role' missing" unless arguments[:role]

          arguments = arguments.clone
          _role = arguments.delete(:role)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'roles', _role
          method  = OpenSearch::API::HTTP_GET
          params  = Utils.__validate_and_extract_params arguments, GET_ROLE_QUERY_PARAMS

          perform_request_complex_ignore404(method, url, params, body, headers, arguments)
        end
      end
    end
  end
end
