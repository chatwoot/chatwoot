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
        CREATE_TENANT_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Creates or replaces the specified tenant.
        #
        # @option arguments [String] :tenant *Required*
        # @option arguments [Hash] :body
        #
        # {API Reference}[https://opensearch.org/docs/2.7/security/access-control/api/#create-tenant]
        def create_tenant(arguments = {})
          raise ArgumentError, "Required argument 'tenant' missing" unless arguments[:tenant]

          arguments = arguments.clone
          _tenant = arguments.delete(:tenant)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'tenants', _tenant
          method  = OpenSearch::API::HTTP_PUT
          params  = Utils.__validate_and_extract_params arguments, CREATE_TENANT_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
