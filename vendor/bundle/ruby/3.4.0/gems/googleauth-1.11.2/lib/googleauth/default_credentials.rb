# Copyright 2015 Google, Inc.
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
require "stringio"

require "googleauth/credentials_loader"
require "googleauth/service_account"
require "googleauth/user_refresh"
require "googleauth/external_account"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # DefaultCredentials is used to preload the credentials file, to determine
    # which type of credentials should be loaded.
    class DefaultCredentials
      extend CredentialsLoader

      # override CredentialsLoader#make_creds to use the class determined by
      # loading the json.
      def self.make_creds options = {}
        json_key_io = options[:json_key_io]
        if json_key_io
          json_key, clz = determine_creds_class json_key_io
          io = StringIO.new MultiJson.dump(json_key)
          clz.make_creds options.merge(json_key_io: io)
        else
          clz = read_creds
          clz.make_creds options
        end
      end

      def self.read_creds
        env_var = CredentialsLoader::ACCOUNT_TYPE_VAR
        type = ENV[env_var]
        raise "#{env_var} is undefined in env" unless type
        case type
        when "service_account"
          ServiceAccountCredentials
        when "authorized_user"
          UserRefreshCredentials
        when "external_account"
          ExternalAccount::Credentials
        else
          raise "credentials type '#{type}' is not supported"
        end
      end

      # Reads the input json and determines which creds class to use.
      def self.determine_creds_class json_key_io
        json_key = MultiJson.load json_key_io.read
        key = "type"
        raise "the json is missing the '#{key}' field" unless json_key.key? key
        type = json_key[key]
        case type
        when "service_account"
          [json_key, ServiceAccountCredentials]
        when "authorized_user"
          [json_key, UserRefreshCredentials]
        when "external_account"
          [json_key, ExternalAccount::Credentials]
        else
          raise "credentials type '#{type}' is not supported"
        end
      end
    end
  end
end
