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
        PATCH_ROLE_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Updates individual attributes of a role.
        #
        # @option arguments [String] :role *Required*
        # @option arguments [Hash] :body *Required*
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#patch-role]
        def patch_role(arguments = {})
          raise ArgumentError, "Required argument 'role' missing" unless arguments[:role]
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          arguments = arguments.clone
          _role = arguments.delete(:role)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'roles', _role
          method  = OpenSearch::API::HTTP_PATCH
          params  = Utils.__validate_and_extract_params arguments, PATCH_ROLE_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
