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
        GET_ROLE_MAPPING_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Retrieves one role mapping.
        #
        # @option arguments [String] :role *Required*
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#get-role-mapping]
        def get_role_mapping(arguments = {})
          raise ArgumentError, "Required argument 'role' missing" unless arguments[:role]

          arguments = arguments.clone
          _role = arguments.delete(:role)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'rolesmapping', _role
          method  = OpenSearch::API::HTTP_GET
          params  = Utils.__validate_and_extract_params arguments, GET_ROLE_MAPPING_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
