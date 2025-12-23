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
      # Gets all PITs.
      def get_all_pits(arguments = {})
        method = OpenSearch::API::HTTP_GET
        path = '_search/point_in_time/_all'
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
        body = nil

        perform_request(method, path, params, body).body
      end

      ParamsRegistry.register(:get_all_pits, [].freeze)
    end
  end
end
