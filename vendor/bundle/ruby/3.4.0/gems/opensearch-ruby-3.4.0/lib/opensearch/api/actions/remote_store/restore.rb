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
    module RemoteStore
      module Actions
        RESTORE_QUERY_PARAMS = Set.new(%i[
          cluster_manager_timeout
          wait_for_completion
        ]).freeze

        # Restores from remote store.
        #
        # @option arguments [Time] :cluster_manager_timeout Operation timeout for connection to cluster-manager node.
        # @option arguments [Boolean] :wait_for_completion Should this request wait until the operation has completed before returning.
        # @option arguments [Hash] :body *Required* Comma-separated list of index IDs
        #
        # {API Reference}[https://opensearch.org/docs/latest/opensearch/remote/#restoring-from-a-backup]
        def restore(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          arguments = arguments.clone
          headers = arguments.delete(:headers) || {}
          body    = arguments.delete(:body)
          url     = Utils.__pathify '_remotestore', '_restore'
          method  = OpenSearch::API::HTTP_POST
          params  = Utils.__validate_and_extract_params arguments, RESTORE_QUERY_PARAMS

          perform_request(method, url, params, body, headers).body
        end
      end
    end
  end
end
