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
        GET_USER_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Retrieve one internal user.
        #
        # @option arguments [String] :username *Required*
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#get-user]
        def get_user(arguments = {})
          raise ArgumentError, "Required argument 'username' missing" unless arguments[:username]

          arguments = arguments.clone
          _username = arguments.delete(:username)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'internalusers', _username
          method  = OpenSearch::API::HTTP_GET
          params  = Utils.__validate_and_extract_params arguments, GET_USER_QUERY_PARAMS

          perform_request_complex_ignore404(method, url, params, body, headers, arguments)
        end
      end
    end
  end
end
