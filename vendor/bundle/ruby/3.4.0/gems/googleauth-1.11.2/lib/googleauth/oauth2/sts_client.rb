# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "googleauth/helpers/connection"

module Google
  module Auth
    module OAuth2
      # OAuth 2.0 Token Exchange Spec.
      # This module defines a token exchange utility based on the
      # [OAuth 2.0 Token Exchange](https://tools.ietf.org/html/rfc8693) spec. This will be mainly
      # used to exchange external credentials for GCP access tokens in workload identity pools to
      # access Google APIs.
      # The implementation will support various types of client authentication as allowed in the spec.
      #
      # A deviation on the spec will be for additional Google specific options that cannot be easily
      # mapped to parameters defined in the RFC.
      # The returned dictionary response will be based on the [rfc8693 section 2.2.1]
      # (https://tools.ietf.org/html/rfc8693#section-2.2.1) spec JSON response.
      #
      class STSClient
        include Helpers::Connection

        URLENCODED_HEADERS = { "Content-Type": "application/x-www-form-urlencoded" }.freeze

        # Create a new instance of the STSClient.
        #
        # @param [String] token_exchange_endpoint
        #  The token exchange endpoint.
        def initialize options = {}
          raise "Token exchange endpoint can not be nil" if options[:token_exchange_endpoint].nil?
          self.default_connection = options[:connection]
          @token_exchange_endpoint = options[:token_exchange_endpoint]
        end

        # Exchanges the provided token for another type of token based on the
        # rfc8693 spec
        #
        # @param [Faraday instance] connection
        # A callable faraday instance used to make HTTP requests.
        # @param [String] grant_type
        #   The OAuth 2.0 token exchange grant type.
        # @param [String] subject_token
        #   The OAuth 2.0 token exchange subject token.
        # @param [String] subject_token_type
        #   The OAuth 2.0 token exchange subject token type.
        # @param [String] resource
        #   The optional OAuth 2.0 token exchange resource field.
        # @param [String] audience
        #   The optional OAuth 2.0 token exchange audience field.
        # @param [Array<String>] scopes
        #   The optional list of scopes to use.
        # @param [String] requested_token_type
        #   The optional OAuth 2.0 token exchange requested token type.
        # @param additional_headers (Hash<String,String>):
        #   The optional additional headers to pass to the token exchange endpoint.
        #
        # @return [Hash] A hash containing the token exchange response.
        def exchange_token options = {}
          missing_required_opts = [:grant_type, :subject_token, :subject_token_type] - options.keys
          unless missing_required_opts.empty?
            raise ArgumentError, "Missing required options: #{missing_required_opts.join ', '}"
          end

          # TODO: Add the ability to add authentication to the headers
          headers = URLENCODED_HEADERS.dup.merge(options[:additional_headers] || {})

          request_body = make_request options

          response = connection.post @token_exchange_endpoint, URI.encode_www_form(request_body), headers

          if response.status != 200
            raise "Token exchange failed with status #{response.status}"
          end

          MultiJson.load response.body
        end

        private

        def make_request options = {}
          request_body = {
            grant_type: options[:grant_type],
            audience: options[:audience],
            scope: Array(options[:scopes])&.join(" ") || [],
            requested_token_type: options[:requested_token_type],
            subject_token: options[:subject_token],
            subject_token_type: options[:subject_token_type]
          }
          unless options[:additional_options].nil?
            request_body[:options] = CGI.escape MultiJson.dump(options[:additional_options], symbolize_name: true)
          end
          request_body
        end
      end
    end
  end
end
