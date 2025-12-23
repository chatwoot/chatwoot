# Copyright 2020 Google LLC
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

require 'google/apis/core/base_service'
require 'google/apis/core/json_representation'
require 'google/apis/core/hashable'
require 'google/apis/errors'

module Google
  module Apis
    module IamcredentialsV1
      # IAM Service Account Credentials API
      #
      # Creates short-lived credentials for impersonating IAM service accounts.
      #  Disabling this API also disables the IAM API (iam.googleapis.com). However,
      #  enabling this API doesn't enable the IAM API.
      #
      # @example
      #    require 'google/apis/iamcredentials_v1'
      #
      #    Iamcredentials = Google::Apis::IamcredentialsV1 # Alias the module
      #    service = Iamcredentials::IAMCredentialsService.new
      #
      # @see https://cloud.google.com/iam/docs/creating-short-lived-service-account-credentials
      class IAMCredentialsService < Google::Apis::Core::BaseService
        DEFAULT_ENDPOINT_TEMPLATE = "https://iamcredentials.$UNIVERSE_DOMAIN$/"

        # @return [String]
        #  API key. Your API key identifies your project and provides you with API access,
        #  quota, and reports. Required unless you provide an OAuth 2.0 token.
        attr_accessor :key

        # @return [String]
        #  Available to use for quota purposes for server-side applications. Can be any
        #  arbitrary string assigned to a user, but should not exceed 40 characters.
        attr_accessor :quota_user

        def initialize
          super(DEFAULT_ENDPOINT_TEMPLATE, '',
                client_name: 'google-apis-iamcredentials_v1',
                client_version: Google::Apis::IamcredentialsV1::GEM_VERSION)
          @batch_path = 'batch'
        end
        
        # Generates an OAuth 2.0 access token for a service account.
        # @param [String] name
        #   Required. The resource name of the service account for which the credentials
        #   are requested, in the following format: `projects/-/serviceAccounts/`
        #   ACCOUNT_EMAIL_OR_UNIQUEID``. The `-` wildcard character is required; replacing
        #   it with a project ID is invalid.
        # @param [Google::Apis::IamcredentialsV1::GenerateAccessTokenRequest] generate_access_token_request_object
        # @param [String] fields
        #   Selector specifying which fields to include in a partial response.
        # @param [String] quota_user
        #   Available to use for quota purposes for server-side applications. Can be any
        #   arbitrary string assigned to a user, but should not exceed 40 characters.
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [Google::Apis::IamcredentialsV1::GenerateAccessTokenResponse] parsed result object
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [Google::Apis::IamcredentialsV1::GenerateAccessTokenResponse]
        #
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def generate_service_account_access_token(name, generate_access_token_request_object = nil, fields: nil, quota_user: nil, options: nil, &block)
          command = make_simple_command(:post, 'v1/{+name}:generateAccessToken', options)
          command.request_representation = Google::Apis::IamcredentialsV1::GenerateAccessTokenRequest::Representation
          command.request_object = generate_access_token_request_object
          command.response_representation = Google::Apis::IamcredentialsV1::GenerateAccessTokenResponse::Representation
          command.response_class = Google::Apis::IamcredentialsV1::GenerateAccessTokenResponse
          command.params['name'] = name unless name.nil?
          command.query['fields'] = fields unless fields.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
          execute_or_queue_command(command, &block)
        end
        
        # Generates an OpenID Connect ID token for a service account.
        # @param [String] name
        #   Required. The resource name of the service account for which the credentials
        #   are requested, in the following format: `projects/-/serviceAccounts/`
        #   ACCOUNT_EMAIL_OR_UNIQUEID``. The `-` wildcard character is required; replacing
        #   it with a project ID is invalid.
        # @param [Google::Apis::IamcredentialsV1::GenerateIdTokenRequest] generate_id_token_request_object
        # @param [String] fields
        #   Selector specifying which fields to include in a partial response.
        # @param [String] quota_user
        #   Available to use for quota purposes for server-side applications. Can be any
        #   arbitrary string assigned to a user, but should not exceed 40 characters.
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [Google::Apis::IamcredentialsV1::GenerateIdTokenResponse] parsed result object
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [Google::Apis::IamcredentialsV1::GenerateIdTokenResponse]
        #
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def generate_service_account_id_token(name, generate_id_token_request_object = nil, fields: nil, quota_user: nil, options: nil, &block)
          command = make_simple_command(:post, 'v1/{+name}:generateIdToken', options)
          command.request_representation = Google::Apis::IamcredentialsV1::GenerateIdTokenRequest::Representation
          command.request_object = generate_id_token_request_object
          command.response_representation = Google::Apis::IamcredentialsV1::GenerateIdTokenResponse::Representation
          command.response_class = Google::Apis::IamcredentialsV1::GenerateIdTokenResponse
          command.params['name'] = name unless name.nil?
          command.query['fields'] = fields unless fields.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
          execute_or_queue_command(command, &block)
        end
        
        # Returns the trust boundary info for a given service account.
        # @param [String] name
        #   Required. Resource name of service account.
        # @param [String] fields
        #   Selector specifying which fields to include in a partial response.
        # @param [String] quota_user
        #   Available to use for quota purposes for server-side applications. Can be any
        #   arbitrary string assigned to a user, but should not exceed 40 characters.
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [Google::Apis::IamcredentialsV1::ServiceAccountAllowedLocations] parsed result object
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [Google::Apis::IamcredentialsV1::ServiceAccountAllowedLocations]
        #
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def get_project_service_account_allowed_locations(name, fields: nil, quota_user: nil, options: nil, &block)
          command = make_simple_command(:get, 'v1/{+name}/allowedLocations', options)
          command.response_representation = Google::Apis::IamcredentialsV1::ServiceAccountAllowedLocations::Representation
          command.response_class = Google::Apis::IamcredentialsV1::ServiceAccountAllowedLocations
          command.params['name'] = name unless name.nil?
          command.query['fields'] = fields unless fields.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
          execute_or_queue_command(command, &block)
        end
        
        # Signs a blob using a service account's system-managed private key.
        # @param [String] name
        #   Required. The resource name of the service account for which the credentials
        #   are requested, in the following format: `projects/-/serviceAccounts/`
        #   ACCOUNT_EMAIL_OR_UNIQUEID``. The `-` wildcard character is required; replacing
        #   it with a project ID is invalid.
        # @param [Google::Apis::IamcredentialsV1::SignBlobRequest] sign_blob_request_object
        # @param [String] fields
        #   Selector specifying which fields to include in a partial response.
        # @param [String] quota_user
        #   Available to use for quota purposes for server-side applications. Can be any
        #   arbitrary string assigned to a user, but should not exceed 40 characters.
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [Google::Apis::IamcredentialsV1::SignBlobResponse] parsed result object
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [Google::Apis::IamcredentialsV1::SignBlobResponse]
        #
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def sign_service_account_blob(name, sign_blob_request_object = nil, fields: nil, quota_user: nil, options: nil, &block)
          command = make_simple_command(:post, 'v1/{+name}:signBlob', options)
          command.request_representation = Google::Apis::IamcredentialsV1::SignBlobRequest::Representation
          command.request_object = sign_blob_request_object
          command.response_representation = Google::Apis::IamcredentialsV1::SignBlobResponse::Representation
          command.response_class = Google::Apis::IamcredentialsV1::SignBlobResponse
          command.params['name'] = name unless name.nil?
          command.query['fields'] = fields unless fields.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
          execute_or_queue_command(command, &block)
        end
        
        # Signs a JWT using a service account's system-managed private key.
        # @param [String] name
        #   Required. The resource name of the service account for which the credentials
        #   are requested, in the following format: `projects/-/serviceAccounts/`
        #   ACCOUNT_EMAIL_OR_UNIQUEID``. The `-` wildcard character is required; replacing
        #   it with a project ID is invalid.
        # @param [Google::Apis::IamcredentialsV1::SignJwtRequest] sign_jwt_request_object
        # @param [String] fields
        #   Selector specifying which fields to include in a partial response.
        # @param [String] quota_user
        #   Available to use for quota purposes for server-side applications. Can be any
        #   arbitrary string assigned to a user, but should not exceed 40 characters.
        # @param [Google::Apis::RequestOptions] options
        #   Request-specific options
        #
        # @yield [result, err] Result & error if block supplied
        # @yieldparam result [Google::Apis::IamcredentialsV1::SignJwtResponse] parsed result object
        # @yieldparam err [StandardError] error object if request failed
        #
        # @return [Google::Apis::IamcredentialsV1::SignJwtResponse]
        #
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def sign_service_account_jwt(name, sign_jwt_request_object = nil, fields: nil, quota_user: nil, options: nil, &block)
          command = make_simple_command(:post, 'v1/{+name}:signJwt', options)
          command.request_representation = Google::Apis::IamcredentialsV1::SignJwtRequest::Representation
          command.request_object = sign_jwt_request_object
          command.response_representation = Google::Apis::IamcredentialsV1::SignJwtResponse::Representation
          command.response_class = Google::Apis::IamcredentialsV1::SignJwtResponse
          command.params['name'] = name unless name.nil?
          command.query['fields'] = fields unless fields.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
          execute_or_queue_command(command, &block)
        end

        protected

        def apply_command_defaults(command)
          command.query['key'] = key unless key.nil?
          command.query['quotaUser'] = quota_user unless quota_user.nil?
        end
      end
    end
  end
end
