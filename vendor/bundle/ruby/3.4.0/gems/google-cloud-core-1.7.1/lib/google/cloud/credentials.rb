# Copyright 2014 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is now considered DEPRECATED.
# Libraries that depend on google-cloud-core ~> 1.1 should not use this file.
# Keep the implementation in place to remain compatible with so older gems.


require "json"
require "signet/oauth_2/client"
require "forwardable"
require "googleauth"

module Google
  module Cloud
    ##
    # @private
    # Represents the OAuth 2.0 signing logic.
    # This class is intended to be inherited by API-specific classes
    # which overrides the SCOPE constant.
    class Credentials
      TOKEN_CREDENTIAL_URI = "https://oauth2.googleapis.com/token".freeze
      AUDIENCE = "https://oauth2.googleapis.com/token".freeze
      SCOPE = [].freeze
      PATH_ENV_VARS = ["GOOGLE_CLOUD_KEYFILE", "GCLOUD_KEYFILE"].freeze
      JSON_ENV_VARS = ["GOOGLE_CLOUD_KEYFILE_JSON", "GCLOUD_KEYFILE_JSON"].freeze
      DEFAULT_PATHS = ["~/.config/gcloud/application_default_credentials.json"].freeze

      attr_accessor :client

      ##
      # Delegate client methods to the client object.
      extend Forwardable
      def_delegators :@client,
                     :token_credential_uri, :audience,
                     :scope, :issuer, :signing_key

      def initialize keyfile, scope: nil
        verify_keyfile_provided! keyfile
        case keyfile
        when Signet::OAuth2::Client
          @client = keyfile
        when Hash
          hash = stringify_hash_keys keyfile
          hash["scope"] ||= scope
          @client = init_client hash
        else
          verify_keyfile_exists! keyfile
          json = JSON.parse ::File.read(keyfile)
          json["scope"] ||= scope
          @client = init_client json
        end
        @client.fetch_access_token!
      end

      ##
      # Returns the default credentials.
      #
      def self.default scope: nil
        env  = ->(v) { ENV[v] }
        json = ->(v) { JSON.parse ENV[v] rescue nil unless ENV[v].nil? }
        path = ->(p) { ::File.file? p }

        # First try to find keyfile file from environment variables.
        self::PATH_ENV_VARS.map(&env).compact.select(&path).each do |file|
          return new file, scope: scope
        end
        # Second try to find keyfile json from environment variables.
        self::JSON_ENV_VARS.map(&json).compact.each do |hash|
          return new hash, scope: scope
        end
        # Third try to find keyfile file from known file paths.
        self::DEFAULT_PATHS.select(&path).each do |file|
          return new file, scope: scope
        end
        # Finally get instantiated client from Google::Auth.
        scope ||= self::SCOPE
        client = Google::Auth.get_application_default scope
        new client
      end

      protected

      ##
      # Verify that the keyfile argument is provided.
      def verify_keyfile_provided! keyfile
        raise "You must provide a keyfile to connect with." if keyfile.nil?
      end

      ##
      # Verify that the keyfile argument is a file.
      def verify_keyfile_exists! keyfile
        exists = ::File.file? keyfile
        raise "The keyfile '#{keyfile}' is not a valid file." unless exists
      end

      ##
      # Initializes the Signet client.
      def init_client keyfile
        client_opts = client_options keyfile
        Signet::OAuth2::Client.new client_opts
      end

      ##
      # returns a new Hash with string keys instead of symbol keys.
      def stringify_hash_keys hash
        hash.transform_keys(&:to_s)
      end

      def client_options options
        # Keyfile options have higher priority over constructor defaults
        options["token_credential_uri"] ||= self.class::TOKEN_CREDENTIAL_URI
        options["audience"]             ||= self.class::AUDIENCE
        options["scope"]                ||= self.class::SCOPE

        # client options for initializing signet client
        { token_credential_uri: options["token_credential_uri"],
          audience:             options["audience"],
          scope:                Array(options["scope"]),
          issuer:               options["client_email"],
          signing_key:          OpenSSL::PKey::RSA.new(options["private_key"]) }
      end
    end
  end
end
