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
    module Http
      module Actions
        # Make a customized PATCH request.
        #
        # @option arguments [String] :url Relative path to the endpoint (e.g. 'cat/indices/books,movies') (*Required*)
        # @option arguments [Hash] :params Querystring parameters to be appended to the path
        # @option arguments [Hash] :headers Custom HTTP headers
        # @option arguments [String | Hash | Array<Hash>] :body The body of the request
        def patch(url, headers: {}, body: nil, params: {})
          request('PATCH', url, headers: headers, body: body, params: params)
        end
      end
    end
  end
end
