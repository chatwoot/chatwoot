# Copyright 2023 Google, Inc.
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

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # BaseClient is a class used to contain common methods that are required by any
    # Credentials Client, including AwsCredentials, ServiceAccountCredentials,
    # and UserRefreshCredentials. This is a superclass of Signet::OAuth2::Client
    # and has been created to create a generic interface for all credentials clients
    # to use, including ones which do not inherit from Signet::OAuth2::Client.
    module BaseClient
      AUTH_METADATA_KEY = :authorization

      # Updates a_hash updated with the authentication token
      def apply! a_hash, opts = {}
        # fetch the access token there is currently not one, or if the client
        # has expired
        fetch_access_token! opts if needs_access_token?
        a_hash[AUTH_METADATA_KEY] = "Bearer #{send token_type}"
      end

      # Returns a clone of a_hash updated with the authentication token
      def apply a_hash, opts = {}
        a_copy = a_hash.clone
        apply! a_copy, opts
        a_copy
      end

      # Whether the id_token or access_token is missing or about to expire.
      def needs_access_token?
        send(token_type).nil? || expires_within?(60)
      end

      # Returns a reference to the #apply method, suitable for passing as
      # a closure
      def updater_proc
        proc { |a_hash, opts = {}| apply a_hash, opts }
      end

      def on_refresh &block
        @refresh_listeners = [] unless defined? @refresh_listeners
        @refresh_listeners << block
      end

      def notify_refresh_listeners
        listeners = defined?(@refresh_listeners) ? @refresh_listeners : []
        listeners.each do |block|
          block.call self
        end
      end

      def expires_within?
        raise NoMethodError, "expires_within? not implemented"
      end

      private

      def token_type
        raise NoMethodError, "token_type not implemented"
      end

      def fetch_access_token!
        raise NoMethodError, "fetch_access_token! not implemented"
      end
    end
  end
end
