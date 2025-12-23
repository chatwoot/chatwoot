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
        PATCH_CONFIGURATION_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # A PATCH call is used to update the existing configuration using the REST API.
        #
        # @option arguments [Hash] :body *Required*
        #
        # {API Reference}[https://opensearch.org/docs/2.7/security/access-control/api/#patch-configuration]
        def patch_configuration(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          arguments = arguments.clone
          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'securityconfig'
          method  = OpenSearch::API::HTTP_PATCH
          params  = Utils.__validate_and_extract_params arguments, PATCH_CONFIGURATION_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
