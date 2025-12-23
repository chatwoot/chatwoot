# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.

module OpenSearch
  module API
    module Actions
      # Deletes one or several PITs.
      #
      # @option arguments [Hash] body: Must include `pit_id`, which is an array of PIT IDs to be deleted. (required)
      def delete_pit(arguments = {})
        raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

        method = OpenSearch::API::HTTP_DELETE
        path = '_search/point_in_time'
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
        body = arguments[:body]

        perform_request(method, path, params, body).body
      end

      ParamsRegistry.register(:delete_pit, [].freeze)
    end
  end
end
