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
    module Cat
      module Actions
        # Retrieves info of certain PIT segments
        #
        # @option arguments [Hash] body: Must include `pit_id`, which is an array of PIT IDs. (required)
        # @option arguments [String] :format a short version of the Accept header, e.g. json, yaml
        # @option arguments [List] :h Comma-separated list of column names to display
        # @option arguments [Boolean] :help Return help information
        # @option arguments [List] :s Comma-separated list of column names or column aliases to sort by
        # @option arguments [Boolean] :v Verbose mode. Display column headers
        # @option arguments [Hash] :headers Custom HTTP headers
        def pit_segments(arguments = {})
          raise ArgumentError, "Required argument 'body' missing" unless arguments[:body]

          arguments = arguments.clone
          headers = arguments.delete(:headers) || {}

          method = OpenSearch::API::HTTP_GET
          path   = '_cat/pit_segments'
          params = Utils.__validate_and_extract_params arguments, ParamsRegistry.get(__method__)
          params[:h] = Utils.__listify(params[:h]) if params[:h]

          body = arguments[:body]
          perform_request(method, path, params, body, headers).body
        end

        ParamsRegistry.register(:pit_segments, %i[
          format
          h
          help
          s
          v
        ].freeze)
      end
    end
  end
end
