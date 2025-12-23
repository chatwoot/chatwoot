# Copyright 2010 Google Inc.
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

require 'json'
require 'googleauth'


module Google
  class APIClient
    ##
    # Manages the persistence of client configuration data and secrets. Format
    # inspired by the Google API Python client.
    #
    # @see https://developers.google.com/api-client-library/python/guide/aaa_client_secrets
    # @deprecated Use google-auth-library-ruby instead
    # @example
    #   {
    #     "web": {
    #       "client_id": "asdfjasdljfasdkjf",
    #       "client_secret": "1912308409123890",
    #       "redirect_uris": ["https://www.example.com/oauth2callback"],
    #       "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    #       "token_uri": "https://accounts.google.com/o/oauth2/token"
    #     }
    #   }
    #
    # @example
    #   {
    #     "installed": {
    #       "client_id": "837647042410-75ifg...usercontent.com",
    #       "client_secret":"asdlkfjaskd",
    #       "redirect_uris": ["http://localhost", "urn:ietf:oauth:2.0:oob"],
    #       "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    #       "token_uri": "https://accounts.google.com/o/oauth2/token"
    #     }
    #   }
    class ClientSecrets
      ##
      # Reads client configuration from a file
      #
      # @param [String] filename
      #   Path to file to load
      #
      # @return [Google::APIClient::ClientSecrets]
      #   OAuth client settings
      def self.load(filename=nil)
        if filename && File.directory?(filename)
          search_path = File.expand_path(filename)
          filename = nil
        end
        while filename == nil
          search_path ||= File.expand_path('.')
          if File.exist?(File.join(search_path, 'client_secrets.json'))
            filename = File.join(search_path, 'client_secrets.json')
          elsif search_path == File.expand_path('..', search_path)
            raise ArgumentError,
              'No client_secrets.json filename supplied ' +
              'and/or could not be found in search path.'
          else
            search_path = File.expand_path(File.join(search_path, '..'))
          end
        end
        data = File.open(filename, 'r') { |file| JSON.load(file.read) }
        return self.new(data)
      end

      ##
      # Initialize OAuth client settings.
      #
      # @param [Hash] options
      #   Parsed client secrets files
      def initialize(options={})
        # Client auth configuration
        @flow = options[:flow] || options.keys.first.to_s || 'web'
        fdata = options[@flow.to_sym] || options[@flow]
        @client_id = fdata[:client_id] || fdata["client_id"]
        @client_secret = fdata[:client_secret] || fdata["client_secret"]
        @redirect_uris = fdata[:redirect_uris] || fdata["redirect_uris"]
        @redirect_uris ||= [fdata[:redirect_uri] || fdata["redirect_uri"]].compact
        @javascript_origins = (
          fdata[:javascript_origins] ||
          fdata["javascript_origins"]
        )
        @javascript_origins ||= [fdata[:javascript_origin] || fdata["javascript_origin"]].compact
        @authorization_uri = fdata[:auth_uri] || fdata["auth_uri"]
        @authorization_uri ||= fdata[:authorization_uri]
        @token_credential_uri = fdata[:token_uri] || fdata["token_uri"]
        @token_credential_uri ||= fdata[:token_credential_uri]

        # Associated token info
        @access_token = fdata[:access_token] || fdata["access_token"]
        @refresh_token = fdata[:refresh_token] || fdata["refresh_token"]
        @id_token = fdata[:id_token] || fdata["id_token"]
        @expires_in = fdata[:expires_in] || fdata["expires_in"]
        @expires_at = fdata[:expires_at] || fdata["expires_at"]
        @issued_at = fdata[:issued_at] || fdata["issued_at"]
      end

      attr_reader(
        :flow, :client_id, :client_secret, :redirect_uris, :javascript_origins,
        :authorization_uri, :token_credential_uri, :access_token,
        :refresh_token, :id_token, :expires_in, :expires_at, :issued_at
      )

      ##
      # Serialize back to the original JSON form
      #
      # @return [String]
      #   JSON
      def to_json
        return Json.dump(to_hash)
      end

      def to_hash
        {
          self.flow => ({
            'client_id' => self.client_id,
            'client_secret' => self.client_secret,
            'redirect_uris' => self.redirect_uris,
            'javascript_origins' => self.javascript_origins,
            'auth_uri' => self.authorization_uri,
            'token_uri' => self.token_credential_uri,
            'access_token' => self.access_token,
            'refresh_token' => self.refresh_token,
            'id_token' => self.id_token,
            'expires_in' => self.expires_in,
            'expires_at' => self.expires_at,
            'issued_at' => self.issued_at
          }).inject({}) do |accu, (k, v)|
            # Prunes empty values from JSON output.
            unless v == nil || (v.respond_to?(:empty?) && v.empty?)
              accu[k] = v
            end
            accu
          end
        }
      end

      def to_authorization
        # NOTE: Do not rely on this default value, as it may change
        new_authorization = Signet::OAuth2::Client.new
        new_authorization.client_id = self.client_id
        new_authorization.client_secret = self.client_secret
        new_authorization.authorization_uri = (
          self.authorization_uri ||
          'https://accounts.google.com/o/oauth2/auth'
        )
        new_authorization.token_credential_uri = (
          self.token_credential_uri ||
          'https://accounts.google.com/o/oauth2/token'
        )
        new_authorization.redirect_uri = self.redirect_uris.first

        # These are supported, but unlikely.
        new_authorization.access_token = self.access_token
        new_authorization.refresh_token = self.refresh_token
        new_authorization.id_token = self.id_token
        new_authorization.expires_in = self.expires_in
        new_authorization.issued_at = self.issued_at if self.issued_at
        new_authorization.expires_at = self.expires_at if self.expires_at
        return new_authorization
      end
    end
  end
end
