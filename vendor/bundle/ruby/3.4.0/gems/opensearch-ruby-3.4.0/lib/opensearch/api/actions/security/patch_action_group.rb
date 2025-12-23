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
        PATCH_ACTION_GROUP_QUERY_PARAMS = Set.new(%i[
        ]).freeze

        # Updates individual attributes of an action group.
        #
        # @option arguments [String] :action_group *Required*
        # @option arguments [Hash] :body
        #
        # {API Reference}[https://opensearch.org/docs/latest/security/access-control/api/#patch-action-group]
        def patch_action_group(arguments = {})
          raise ArgumentError, "Required argument 'action_group' missing" unless arguments[:action_group]

          arguments = arguments.clone
          _action_group = arguments.delete(:action_group)

          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_plugins', '_security', 'api', 'actiongroups', _action_group
          method  = OpenSearch::API::HTTP_PATCH
          params  = Utils.__validate_and_extract_params arguments, PATCH_ACTION_GROUP_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
