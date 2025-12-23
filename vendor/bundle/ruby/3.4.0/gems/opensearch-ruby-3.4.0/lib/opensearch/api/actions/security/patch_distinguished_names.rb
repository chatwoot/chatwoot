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
        PATCH_DISTINGUISHED_NAMES_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Bulk update of distinguished names.
        #
        # @option arguments [Hash] :body *Required*
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#update-all-distinguished-names]
        def patch_distinguished_names(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          arguments = arguments.clone
          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'nodesdn'
          method  = OpenSearch::API::HTTP_PATCH
          params  = Utils.__validate_and_extract_params arguments, PATCH_DISTINGUISHED_NAMES_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
