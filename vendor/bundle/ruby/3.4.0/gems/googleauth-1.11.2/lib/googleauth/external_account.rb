# Copyright 2022 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "time"
require "uri"
require "googleauth/credentials_loader"
require "googleauth/external_account/aws_credentials"
require "googleauth/external_account/identity_pool_credentials"
require "googleauth/external_account/pluggable_credentials"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using External Account credentials, such
    # as those provided by the AWS provider.
    module ExternalAccount
      # Provides an entrypoint for all Exernal Account credential classes.
      class Credentials
        # The subject token type used for AWS external_account credentials.
        AWS_SUBJECT_TOKEN_TYPE = "urn:ietf:params:aws:token-type:aws4_request".freeze
        MISSING_CREDENTIAL_SOURCE = "missing credential source for external account".freeze
        INVALID_EXTERNAL_ACCOUNT_TYPE = "credential source is not supported external account type".freeze

        # Create a ExternalAccount::Credentials
        #
        # @param json_key_io [IO] an IO from which the JSON key can be read
        # @param scope [String,Array,nil] the scope(s) to access
        def self.make_creds options = {}
          json_key_io, scope = options.values_at :json_key_io, :scope

          raise "A json file is required for external account credentials." unless json_key_io
          user_creds = read_json_key json_key_io

          # AWS credentials is determined by aws subject token type
          return make_aws_credentials user_creds, scope if user_creds[:subject_token_type] == AWS_SUBJECT_TOKEN_TYPE

          raise MISSING_CREDENTIAL_SOURCE if user_creds[:credential_source].nil?
          user_creds[:scope] = scope
          make_external_account_credentials user_creds
        end

        # Reads the required fields from the JSON.
        def self.read_json_key json_key_io
          json_key = MultiJson.load json_key_io.read, symbolize_keys: true
          wanted = [
            :audience, :subject_token_type, :token_url, :credential_source
          ]
          wanted.each do |key|
            raise "the json is missing the #{key} field" unless json_key.key? key
          end
          json_key
        end

        class << self
          private

          def make_aws_credentials user_creds, scope
            Google::Auth::ExternalAccount::AwsCredentials.new(
              audience: user_creds[:audience],
              scope: scope,
              subject_token_type: user_creds[:subject_token_type],
              token_url: user_creds[:token_url],
              credential_source: user_creds[:credential_source],
              service_account_impersonation_url: user_creds[:service_account_impersonation_url],
              universe_domain: user_creds[:universe_domain]
            )
          end

          def make_external_account_credentials user_creds
            unless user_creds[:credential_source][:file].nil? && user_creds[:credential_source][:url].nil?
              return Google::Auth::ExternalAccount::IdentityPoolCredentials.new user_creds
            end
            unless user_creds[:credential_source][:executable].nil?
              return Google::Auth::ExternalAccount::PluggableAuthCredentials.new user_creds
            end
            raise INVALID_EXTERNAL_ACCOUNT_TYPE
          end
        end
      end
    end
  end
end
