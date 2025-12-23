# Copyright 2013 Google Inc.
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

require 'signet/oauth_2/client'

module Google
  class APIClient
    ##
    # Represents cached OAuth 2 tokens stored on local disk in a
    # JSON serialized file. Meant to resemble the serialized format
    # http://google-api-python-client.googlecode.com/hg/docs/epy/oauth2client.file.Storage-class.html
    #
    # @deprecated Use google-auth-library-ruby instead
    class Storage

      AUTHORIZATION_URI = 'https://accounts.google.com/o/oauth2/auth'
      TOKEN_CREDENTIAL_URI = 'https://accounts.google.com/o/oauth2/token'

      # @return [Object] Storage object.
      attr_accessor :store

      # @return [Signet::OAuth2::Client]
      attr_reader :authorization

      ##
      # Initializes the Storage object.
      #
      # @param [Object] store
      #  Storage object
      def initialize(store)
        @store= store
        @authorization = nil
      end

      ##
      # Write the credentials to the specified store.
      #
      # @param [Signet::OAuth2::Client] authorization
      #    Optional authorization instance. If not provided, the authorization
      #    already associated with this instance will be written.
      def write_credentials(authorization=nil)
        @authorization = authorization if authorization
        if @authorization.respond_to?(:refresh_token) && @authorization.refresh_token
          store.write_credentials(credentials_hash)
        end
      end

      ##
      # Loads credentials and authorizes an client.
      # @return [Object] Signet::OAuth2::Client or NIL
      def authorize
        @authorization = nil
        cached_credentials = load_credentials
        if cached_credentials && cached_credentials.size > 0
          @authorization = Signet::OAuth2::Client.new(cached_credentials)
          @authorization.issued_at = Time.at(cached_credentials['issued_at'].to_i)
          self.refresh_authorization if @authorization.expired?
        end
        return @authorization
      end

      ##
      # refresh credentials and save them to store
      def refresh_authorization
        authorization.refresh!
        self.write_credentials
      end

      private

      ##
      # Attempt to read in credentials from the specified store.
      def load_credentials
        store.load_credentials
      end

      ##
      # @return [Hash] with credentials
      def credentials_hash
        {
          :access_token          => authorization.access_token,
          :authorization_uri     => AUTHORIZATION_URI,
          :client_id             => authorization.client_id,
          :client_secret         => authorization.client_secret,
          :expires_in            => authorization.expires_in,
          :refresh_token         => authorization.refresh_token,
          :token_credential_uri  => TOKEN_CREDENTIAL_URI,
          :issued_at             => authorization.issued_at.to_i
        }
      end
    end
  end
end
