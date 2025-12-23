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
      module Actions; end

      # Client for the "http" namespace (includes the Http::Actions methods)
      class HttpClient
        include Http::Actions
        include Common::Client
        include Common::Client::Base
      end

      # Proxy method for HttpClient, available in the receiving object
      def http
        @http ||= HttpClient.new(self)
      end
    end
  end
end
