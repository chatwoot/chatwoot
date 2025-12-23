# Copyright 2014 Google, Inc.
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

require "uri"
require "multi_json"
require "googleauth/signet"
require "googleauth/user_refresh"
require "securerandom"

module Google
  module Auth
    # Handles an interactive 3-Legged-OAuth2 (3LO) user consent authorization.
    #
    # Example usage for a simple command line app:
    #
    #     credentials = authorizer.get_credentials(user_id)
    #     if credentials.nil?
    #       url = authorizer.get_authorization_url(
    #         base_url: OOB_URI)
    #       puts "Open the following URL in the browser and enter the " +
    #            "resulting code after authorization"
    #       puts url
    #       code = gets
    #       credentials = authorizer.get_and_store_credentials_from_code(
    #         user_id: user_id, code: code, base_url: OOB_URI)
    #     end
    #     # Credentials ready to use, call APIs
    #     ...
    class UserAuthorizer
      MISMATCHED_CLIENT_ID_ERROR =
        "Token client ID of %s does not match configured client id %s".freeze
      NIL_CLIENT_ID_ERROR = "Client id can not be nil.".freeze
      NIL_SCOPE_ERROR = "Scope can not be nil.".freeze
      NIL_USER_ID_ERROR = "User ID can not be nil.".freeze
      NIL_TOKEN_STORE_ERROR = "Can not call method if token store is nil".freeze
      MISSING_ABSOLUTE_URL_ERROR =
        'Absolute base url required for relative callback url "%s"'.freeze

      # Initialize the authorizer
      #
      # @param [Google::Auth::ClientID] client_id
      #  Configured ID & secret for this application
      # @param [String, Array<String>] scope
      #  Authorization scope to request
      # @param [Google::Auth::Stores::TokenStore] token_store
      #  Backing storage for persisting user credentials
      # @param [String] legacy_callback_uri
      #  URL (either absolute or relative) of the auth callback.
      #  Defaults to '/oauth2callback'.
      #  @deprecated This field is deprecated. Instead, use the keyword
      #   argument callback_uri.
      # @param [String] code_verifier
      #  Random string of 43-128 chars used to verify the key exchange using
      #  PKCE.
      def initialize client_id, scope, token_store,
                     legacy_callback_uri = nil,
                     callback_uri: nil,
                     code_verifier: nil
        raise NIL_CLIENT_ID_ERROR if client_id.nil?
        raise NIL_SCOPE_ERROR if scope.nil?

        @client_id = client_id
        @scope = Array(scope)
        @token_store = token_store
        @callback_uri = legacy_callback_uri || callback_uri || "/oauth2callback"
        @code_verifier = code_verifier
      end

      # Build the URL for requesting authorization.
      #
      # @param [String] login_hint
      #  Login hint if need to authorize a specific account. Should be a
      #  user's email address or unique profile ID.
      # @param [String] state
      #  Opaque state value to be returned to the oauth callback.
      # @param [String] base_url
      #  Absolute URL to resolve the configured callback uri against. Required
      #  if the configured callback uri is a relative.
      # @param [String, Array<String>] scope
      #  Authorization scope to request. Overrides the instance scopes if not
      #  nil.
      # @param [Hash] additional_parameters
      #  Additional query parameters to be added to the authorization URL.
      # @return [String]
      #  Authorization url
      def get_authorization_url options = {}
        scope = options[:scope] || @scope

        options[:additional_parameters] ||= {}

        if @code_verifier
          options[:additional_parameters].merge!(
            {
              code_challenge: generate_code_challenge(@code_verifier),
              code_challenge_method: code_challenge_method
            }
          )
        end

        credentials = UserRefreshCredentials.new(
          client_id:     @client_id.id,
          client_secret: @client_id.secret,
          scope:         scope,
          additional_parameters: options[:additional_parameters]
        )
        redirect_uri = redirect_uri_for options[:base_url]
        url = credentials.authorization_uri(access_type:            "offline",
                                            redirect_uri:           redirect_uri,
                                            approval_prompt:        "force",
                                            state:                  options[:state],
                                            include_granted_scopes: true,
                                            login_hint:             options[:login_hint])
        url.to_s
      end

      # Fetch stored credentials for the user.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [Array<String>, String] scope
      #  If specified, only returns credentials that have all
      #  the requested scopes
      # @return [Google::Auth::UserRefreshCredentials]
      #  Stored credentials, nil if none present
      def get_credentials user_id, scope = nil
        saved_token = stored_token user_id
        return nil if saved_token.nil?
        data = MultiJson.load saved_token

        if data.fetch("client_id", @client_id.id) != @client_id.id
          raise format(MISMATCHED_CLIENT_ID_ERROR,
                       data["client_id"], @client_id.id)
        end

        credentials = UserRefreshCredentials.new(
          client_id:     @client_id.id,
          client_secret: @client_id.secret,
          scope:         data["scope"] || @scope,
          access_token:  data["access_token"],
          refresh_token: data["refresh_token"],
          expires_at:    data.fetch("expiration_time_millis", 0) / 1000
        )
        scope ||= @scope
        return monitor_credentials user_id, credentials if credentials.includes_scope? scope
        nil
      end

      # Exchanges an authorization code returned in the oauth callback
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [String] code
      #  The authorization code from the OAuth callback
      # @param [String, Array<String>] scope
      #  Authorization scope requested. Overrides the instance
      #  scopes if not nil.
      # @param [String] base_url
      #  Absolute URL to resolve the configured callback uri against.
      #  Required if the configured
      #  callback uri is a relative.
      # @param [Hash] additional_parameters
      #  Additional parameters to be added to the post body of token
      #  endpoint request.
      # @return [Google::Auth::UserRefreshCredentials]
      #  Credentials if exchange is successful
      def get_credentials_from_code options = {}
        user_id = options[:user_id]
        code = options[:code]
        scope = options[:scope] || @scope
        base_url = options[:base_url]
        options[:additional_parameters] ||= {}
        options[:additional_parameters].merge!({ code_verifier: @code_verifier })
        credentials = UserRefreshCredentials.new(
          client_id:             @client_id.id,
          client_secret:         @client_id.secret,
          redirect_uri:          redirect_uri_for(base_url),
          scope:                 scope,
          additional_parameters: options[:additional_parameters]
        )
        credentials.code = code
        credentials.fetch_access_token!({})
        monitor_credentials user_id, credentials
      end

      # Exchanges an authorization code returned in the oauth callback.
      # Additionally, stores the resulting credentials in the token store if
      # the exchange is successful.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [String] code
      #  The authorization code from the OAuth callback
      # @param [String, Array<String>] scope
      #  Authorization scope requested. Overrides the instance
      #  scopes if not nil.
      # @param [String] base_url
      #  Absolute URL to resolve the configured callback uri against.
      #  Required if the configured
      #  callback uri is a relative.
      # @return [Google::Auth::UserRefreshCredentials]
      #  Credentials if exchange is successful
      def get_and_store_credentials_from_code options = {}
        credentials = get_credentials_from_code options
        store_credentials options[:user_id], credentials
      end

      # Revokes a user's credentials. This both revokes the actual
      # grant as well as removes the token from the token store.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      def revoke_authorization user_id
        credentials = get_credentials user_id
        if credentials
          begin
            @token_store.delete user_id
          ensure
            credentials.revoke!
          end
        end
        nil
      end

      # Store credentials for a user. Generally not required to be
      # called directly, but may be used to migrate tokens from one
      # store to another.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [Google::Auth::UserRefreshCredentials] credentials
      #  Credentials to store.
      def store_credentials user_id, credentials
        json = MultiJson.dump(
          client_id:              credentials.client_id,
          access_token:           credentials.access_token,
          refresh_token:          credentials.refresh_token,
          scope:                  credentials.scope,
          expiration_time_millis: credentials.expires_at.to_i * 1000
        )
        @token_store.store user_id, json
        credentials
      end

      # The code verifier for PKCE for OAuth 2.0. When set, the
      # authorization URI will contain the Code Challenge and Code
      # Challenge Method querystring parameters, and the token URI will
      # contain the Code Verifier parameter.
      #
      # @param [String|nil] new_code_erifier
      def code_verifier= new_code_verifier
        @code_verifier = new_code_verifier
      end

      # Generate the code verifier needed to be sent while fetching
      # authorization URL.
      def self.generate_code_verifier
        random_number = rand 32..96
        SecureRandom.alphanumeric random_number
      end

      private

      # @private Fetch stored token with given user_id
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @return [String] The saved token from @token_store
      def stored_token user_id
        raise NIL_USER_ID_ERROR if user_id.nil?
        raise NIL_TOKEN_STORE_ERROR if @token_store.nil?

        @token_store.load user_id
      end

      # Begin watching a credential for refreshes so the access token can be
      # saved.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [Google::Auth::UserRefreshCredentials] credentials
      #  Credentials to store.
      def monitor_credentials user_id, credentials
        credentials.on_refresh do |cred|
          store_credentials user_id, cred
        end
        credentials
      end

      # Resolve the redirect uri against a base.
      #
      # @param [String] base_url
      #  Absolute URL to resolve the callback against if necessary.
      # @return [String]
      #  Redirect URI
      def redirect_uri_for base_url
        return @callback_uri if uri_is_postmessage?(@callback_uri) || !URI(@callback_uri).scheme.nil?
        raise format(MISSING_ABSOLUTE_URL_ERROR, @callback_uri) if base_url.nil? || URI(base_url).scheme.nil?
        URI.join(base_url, @callback_uri).to_s
      end

      # Check if URI is Google's postmessage flow (not a valid redirect_uri by spec, but allowed)
      def uri_is_postmessage? uri
        uri.to_s.casecmp("postmessage").zero?
      end

      def generate_code_challenge code_verifier
        digest = Digest::SHA256.digest code_verifier
        Base64.urlsafe_encode64 digest, padding: false
      end

      def code_challenge_method
        "S256"
      end
    end
  end
end
