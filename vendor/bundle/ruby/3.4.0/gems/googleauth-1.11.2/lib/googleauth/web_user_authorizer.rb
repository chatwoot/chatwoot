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

require "multi_json"
require "googleauth/signet"
require "googleauth/user_authorizer"
require "googleauth/user_refresh"
require "securerandom"

module Google
  module Auth
    # Varation on {Google::Auth::UserAuthorizer} adapted for Rack based
    # web applications.
    #
    # Example usage:
    #
    #     get('/') do
    #       user_id = request.session['user_email']
    #       credentials = authorizer.get_credentials(user_id, request)
    #       if credentials.nil?
    #         redirect authorizer.get_authorization_url(user_id: user_id,
    #                                                   request: request)
    #       end
    #       # Credentials are valid, can call APIs
    #       ...
    #    end
    #
    #    get('/oauth2callback') do
    #      url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(
    #        request)
    #      redirect url
    #    end
    #
    # Instead of implementing the callback directly, applications are
    # encouraged to use {Google::Auth::WebUserAuthorizer::CallbackApp} instead.
    #
    # @see CallbackApp
    # @note Requires sessions are enabled
    class WebUserAuthorizer < Google::Auth::UserAuthorizer
      STATE_PARAM = "state".freeze
      AUTH_CODE_KEY = "code".freeze
      ERROR_CODE_KEY = "error".freeze
      SESSION_ID_KEY = "session_id".freeze
      CALLBACK_STATE_KEY = "g-auth-callback".freeze
      CURRENT_URI_KEY = "current_uri".freeze
      XSRF_KEY = "g-xsrf-token".freeze
      SCOPE_KEY = "scope".freeze

      NIL_REQUEST_ERROR = "Request is required.".freeze
      NIL_SESSION_ERROR = "Sessions must be enabled".freeze
      MISSING_AUTH_CODE_ERROR = "Missing authorization code in request".freeze
      AUTHORIZATION_ERROR = "Authorization error: %s".freeze
      INVALID_STATE_TOKEN_ERROR =
        "State token does not match expected value".freeze

      class << self
        attr_accessor :default
      end

      # Handle the result of the oauth callback. This version defers the
      # exchange of the code by temporarily stashing the results in the user's
      # session. This allows apps to use the generic
      # {Google::Auth::WebUserAuthorizer::CallbackApp} handler for the callback
      # without any additional customization.
      #
      # Apps that wish to handle the callback directly should use
      # {#handle_auth_callback} instead.
      #
      # @param [Rack::Request] request
      #  Current request
      def self.handle_auth_callback_deferred request
        callback_state, redirect_uri = extract_callback_state request
        request.session[CALLBACK_STATE_KEY] = MultiJson.dump callback_state
        redirect_uri
      end

      # Initialize the authorizer
      #
      # @param [Google::Auth::ClientID] client_id
      #  Configured ID & secret for this application
      # @param [String, Array<String>] scope
      #  Authorization scope to request
      # @param [Google::Auth::Stores::TokenStore] token_store
      #  Backing storage for persisting user credentials
      # @param [String] legacy_callback_uri
      #  URL (either absolute or relative) of the auth callback. Defaults
      #  to '/oauth2callback'.
      #  @deprecated This field is deprecated. Instead, use the keyword
      #   argument callback_uri.
      # @param [String] code_verifier
      #  Random string of 43-128 chars used to verify the key exchange using
      #  PKCE.
      def initialize client_id, scope, token_store,
                     legacy_callback_uri = nil,
                     callback_uri: nil,
                     code_verifier: nil
        super client_id, scope, token_store,
              legacy_callback_uri,
              code_verifier: code_verifier,
              callback_uri: callback_uri
      end

      # Handle the result of the oauth callback. Exchanges the authorization
      # code from the request and persists to storage.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [Rack::Request] request
      #  Current request
      # @return (Google::Auth::UserRefreshCredentials, String)
      #  credentials & next URL to redirect to
      def handle_auth_callback user_id, request
        callback_state, redirect_uri = WebUserAuthorizer.extract_callback_state(
          request
        )
        WebUserAuthorizer.validate_callback_state callback_state, request
        credentials = get_and_store_credentials_from_code(
          user_id:  user_id,
          code:     callback_state[AUTH_CODE_KEY],
          scope:    callback_state[SCOPE_KEY],
          base_url: request.url
        )
        [credentials, redirect_uri]
      end

      # Build the URL for requesting authorization.
      #
      # @param [String] login_hint
      #  Login hint if need to authorize a specific account. Should be a
      #  user's email address or unique profile ID.
      # @param [Rack::Request] request
      #  Current request
      # @param [String] redirect_to
      #  Optional URL to proceed to after authorization complete. Defaults to
      #  the current URL.
      # @param [String, Array<String>] scope
      #  Authorization scope to request. Overrides the instance scopes if
      #  not nil.
      # @param [Hash] state
      #  Optional key-values to be returned to the oauth callback.
      # @return [String]
      #  Authorization url
      def get_authorization_url options = {}
        options = options.dup
        request = options[:request]
        raise NIL_REQUEST_ERROR if request.nil?
        raise NIL_SESSION_ERROR if request.session.nil?

        state = options[:state] || {}

        redirect_to = options[:redirect_to] || request.url
        request.session[XSRF_KEY] = SecureRandom.base64
        options[:state] = MultiJson.dump(state.merge(
                                           SESSION_ID_KEY  => request.session[XSRF_KEY],
                                           CURRENT_URI_KEY => redirect_to
                                         ))
        options[:base_url] = request.url
        super options
      end

      # Fetch stored credentials for the user from the given request session.
      #
      # @param [String] user_id
      #  Unique ID of the user for loading/storing credentials.
      # @param [Rack::Request] request
      #  Current request. Optional. If omitted, this will attempt to fall back
      #  on the base class behavior of reading from the token store.
      # @param [Array<String>, String] scope
      #  If specified, only returns credentials that have all the \
      #  requested scopes
      # @return [Google::Auth::UserRefreshCredentials]
      #  Stored credentials, nil if none present
      # @raise [Signet::AuthorizationError]
      #  May raise an error if an authorization code is present in the session
      #  and exchange of the code fails
      def get_credentials user_id, request = nil, scope = nil
        if request&.session&.key? CALLBACK_STATE_KEY
          # Note - in theory, no need to check required scope as this is
          # expected to be called immediately after a return from authorization
          state_json = request.session.delete CALLBACK_STATE_KEY
          callback_state = MultiJson.load state_json
          WebUserAuthorizer.validate_callback_state callback_state, request
          get_and_store_credentials_from_code(
            user_id:  user_id,
            code:     callback_state[AUTH_CODE_KEY],
            scope:    callback_state[SCOPE_KEY],
            base_url: request.url
          )
        else
          super user_id, scope
        end
      end

      def self.extract_callback_state request
        state = MultiJson.load(request.params[STATE_PARAM] || "{}")
        redirect_uri = state[CURRENT_URI_KEY]
        callback_state = {
          AUTH_CODE_KEY  => request.params[AUTH_CODE_KEY],
          ERROR_CODE_KEY => request.params[ERROR_CODE_KEY],
          SESSION_ID_KEY => state[SESSION_ID_KEY],
          SCOPE_KEY      => request.params[SCOPE_KEY]
        }
        [callback_state, redirect_uri]
      end

      # Verifies the results of an authorization callback
      #
      # @param [Hash] state
      #  Callback state
      # @option state [String] AUTH_CODE_KEY
      #  The authorization code
      # @option state [String] ERROR_CODE_KEY
      #  Error message if failed
      # @param [Rack::Request] request
      #  Current request
      def self.validate_callback_state state, request
        raise Signet::AuthorizationError, MISSING_AUTH_CODE_ERROR if state[AUTH_CODE_KEY].nil?
        if state[ERROR_CODE_KEY]
          raise Signet::AuthorizationError,
                format(AUTHORIZATION_ERROR, state[ERROR_CODE_KEY])
        elsif request.session[XSRF_KEY] != state[SESSION_ID_KEY]
          raise Signet::AuthorizationError, INVALID_STATE_TOKEN_ERROR
        end
      end

      # Small Rack app which acts as the default callback handler for the app.
      #
      # To configure in Rails, add to routes.rb:
      #
      #     match '/oauth2callback',
      #           to: Google::Auth::WebUserAuthorizer::CallbackApp,
      #           via: :all
      #
      # With Rackup, add to config.ru:
      #
      #     map '/oauth2callback' do
      #       run Google::Auth::WebUserAuthorizer::CallbackApp
      #     end
      #
      # Or in a classic Sinatra app:
      #
      #     get('/oauth2callback') do
      #       Google::Auth::WebUserAuthorizer::CallbackApp.call(env)
      #     end
      #
      # @see Google::Auth::WebUserAuthorizer
      class CallbackApp
        LOCATION_HEADER = "Location".freeze
        REDIR_STATUS = 302
        ERROR_STATUS = 500

        # Handle a rack request. Simply stores the results the authorization
        # in the session temporarily and redirects back to to the previously
        # saved redirect URL. Credentials can be later retrieved by calling.
        # {Google::Auth::Web::WebUserAuthorizer#get_credentials}
        #
        # See {Google::Auth::Web::WebUserAuthorizer#get_authorization_uri}
        # for how to initiate authorization requests.
        #
        # @param [Hash] env
        #  Rack environment
        # @return [Array]
        #  HTTP response
        def self.call env
          request = Rack::Request.new env
          return_url = WebUserAuthorizer.handle_auth_callback_deferred request
          if return_url
            [REDIR_STATUS, { LOCATION_HEADER => return_url }, []]
          else
            [ERROR_STATUS, {}, ["No return URL is present in the request."]]
          end
        end

        def call env
          self.class.call env
        end
      end
    end
  end
end
