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
        UPDATE_DISTINGUISHED_NAMES_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Adds or updates the specified distinguished names in the cluster’s or node’s allow list.
        #
        # @option arguments [String] :cluster_name *Required*
        # @option arguments [Hash] :body
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#update-distinguished-names]
        def update_distinguished_names(arguments = {})
          raise ArgumentError, "Required argument 'cluster_name' missing" unless arguments[:cluster_name]

          arguments = arguments.clone
          _cluster_name = arguments.delete(:cluster_name)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'nodesdn', _cluster_name
          method  = OpenSearch::API::HTTP_PUT
          params  = Utils.__validate_and_extract_params arguments, UPDATE_DISTINGUISHED_NAMES_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
