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
      # Creates a point in time.
      #
      # @option arguments [String] :index The name(s) of the target index(es) for the PIT. May contain a comma-separated list or a wildcard index pattern. (required)
      # @option arguments [String] :keep_alive The amount of time to keep the PIT. (required)
      # @option arguments [String] :preference The node or the shard used to perform the search. (default: random)
      # @option arguments [String] :routing Specifies to route search requests to a specific shard.
      # @option arguments [String] :expand_wildcards The type of index that can match the wildcard pattern. Supports comma-separated values. (default: open)
      # @option arguments [String] :allow_partial_pit_creation Specifies whether to create a PIT with partial failures. (default: false)
      def create_pit(arguments = {})
        raise ArgumentError, "Required argument 'index' missing" unless arguments[:index]
        raise ArgumentError, "Required argument 'keep_alive' missing" unless arguments[:keep_alive]

        arguments = arguments.clone
        _index = arguments.delete(:index)

        method = OpenSearch::API::HTTP_POST
        path = "#{Utils.__listify(_index)}/_search/point_in_time"
        params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
        body = nil

        perform_request(method, path, params, body).body
      end

      ParamsRegistry.register(:create_pit, %i[
        keep_alive
        preference
        routing
        expand_wildcards
        allow_partial_pit_creation
      ].freeze)
    end
  end
end
