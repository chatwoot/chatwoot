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

require "os"
require "rbconfig"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # CredentialsLoader contains the behaviour used to locate and find default
    # credentials files on the file system.
    module CredentialsLoader
      ENV_VAR                   = "GOOGLE_APPLICATION_CREDENTIALS".freeze
      PRIVATE_KEY_VAR           = "GOOGLE_PRIVATE_KEY".freeze
      CLIENT_EMAIL_VAR          = "GOOGLE_CLIENT_EMAIL".freeze
      CLIENT_ID_VAR             = "GOOGLE_CLIENT_ID".freeze
      CLIENT_SECRET_VAR         = "GOOGLE_CLIENT_SECRET".freeze
      REFRESH_TOKEN_VAR         = "GOOGLE_REFRESH_TOKEN".freeze
      ACCOUNT_TYPE_VAR          = "GOOGLE_ACCOUNT_TYPE".freeze
      PROJECT_ID_VAR            = "GOOGLE_PROJECT_ID".freeze
      AWS_REGION_VAR            = "AWS_REGION".freeze
      AWS_DEFAULT_REGION_VAR    = "AWS_DEFAULT_REGION".freeze
      AWS_ACCESS_KEY_ID_VAR     = "AWS_ACCESS_KEY_ID".freeze
      AWS_SECRET_ACCESS_KEY_VAR = "AWS_SECRET_ACCESS_KEY".freeze
      AWS_SESSION_TOKEN_VAR     = "AWS_SESSION_TOKEN".freeze
      GCLOUD_POSIX_COMMAND      = "gcloud".freeze
      GCLOUD_WINDOWS_COMMAND    = "gcloud.cmd".freeze
      GCLOUD_CONFIG_COMMAND     = "config config-helper --format json --verbosity none".freeze

      CREDENTIALS_FILE_NAME = "application_default_credentials.json".freeze
      NOT_FOUND_ERROR = "Unable to read the credential file specified by #{ENV_VAR}".freeze
      WELL_KNOWN_PATH = "gcloud/#{CREDENTIALS_FILE_NAME}".freeze
      WELL_KNOWN_ERROR = "Unable to read the default credential file".freeze

      SYSTEM_DEFAULT_ERROR = "Unable to read the system default credential file".freeze

      CLOUD_SDK_CLIENT_ID = "764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.app" \
                            "s.googleusercontent.com".freeze

      # make_creds proxies the construction of a credentials instance
      #
      # By default, it calls #new on the current class, but this behaviour can
      # be modified, allowing different instances to be created.
      def make_creds *args
        creds = new(*args)
        creds = creds.configure_connection args[0] if creds.respond_to?(:configure_connection) && args.size == 1
        creds
      end

      # Creates an instance from the path specified in an environment
      # variable.
      #
      # @param scope [string|array|nil] the scope(s) to access
      # @param options [Hash] Connection options. These may be used to configure
      #     how OAuth tokens are retrieved, by providing a suitable
      #     `Faraday::Connection`. For example, if a connection proxy must be
      #     used in the current network, you may provide a connection with
      #     with the needed proxy options.
      #     The following keys are recognized:
      #     * `:default_connection` The connection object to use.
      #     * `:connection_builder` A `Proc` that returns a connection.
      def from_env scope = nil, options = {}
        options = interpret_options scope, options
        if ENV.key?(ENV_VAR) && !ENV[ENV_VAR].empty?
          path = ENV[ENV_VAR]
          raise "file #{path} does not exist" unless File.exist? path
          File.open path do |f|
            return make_creds options.merge(json_key_io: f)
          end
        elsif service_account_env_vars? || authorized_user_env_vars?
          make_creds options
        end
      rescue StandardError => e
        raise "#{NOT_FOUND_ERROR}: #{e}"
      end

      # Creates an instance from a well known path.
      #
      # @param scope [string|array|nil] the scope(s) to access
      # @param options [Hash] Connection options. These may be used to configure
      #     how OAuth tokens are retrieved, by providing a suitable
      #     `Faraday::Connection`. For example, if a connection proxy must be
      #     used in the current network, you may provide a connection with
      #     with the needed proxy options.
      #     The following keys are recognized:
      #     * `:default_connection` The connection object to use.
      #     * `:connection_builder` A `Proc` that returns a connection.
      def from_well_known_path scope = nil, options = {}
        options = interpret_options scope, options
        home_var = OS.windows? ? "APPDATA" : "HOME"
        base = WELL_KNOWN_PATH
        root = ENV[home_var].nil? ? "" : ENV[home_var]
        base = File.join ".config", base unless OS.windows?
        path = File.join root, base
        return nil unless File.exist? path
        File.open path do |f|
          return make_creds options.merge(json_key_io: f)
        end
      rescue StandardError => e
        raise "#{WELL_KNOWN_ERROR}: #{e}"
      end

      # Creates an instance from the system default path
      #
      # @param scope [string|array|nil] the scope(s) to access
      # @param options [Hash] Connection options. These may be used to configure
      #     how OAuth tokens are retrieved, by providing a suitable
      #     `Faraday::Connection`. For example, if a connection proxy must be
      #     used in the current network, you may provide a connection with
      #     with the needed proxy options.
      #     The following keys are recognized:
      #     * `:default_connection` The connection object to use.
      #     * `:connection_builder` A `Proc` that returns a connection.
      def from_system_default_path scope = nil, options = {}
        options = interpret_options scope, options
        if OS.windows?
          return nil unless ENV["ProgramData"]
          prefix = File.join ENV["ProgramData"], "Google/Auth"
        else
          prefix = "/etc/google/auth/"
        end
        path = File.join prefix, CREDENTIALS_FILE_NAME
        return nil unless File.exist? path
        File.open path do |f|
          return make_creds options.merge(json_key_io: f)
        end
      rescue StandardError => e
        raise "#{SYSTEM_DEFAULT_ERROR}: #{e}"
      end

      module_function

      # Finds project_id from gcloud CLI configuration
      def load_gcloud_project_id
        gcloud = GCLOUD_WINDOWS_COMMAND if OS.windows?
        gcloud = GCLOUD_POSIX_COMMAND unless OS.windows?
        gcloud_json = IO.popen("#{gcloud} #{GCLOUD_CONFIG_COMMAND}", in: :close, err: :close, &:read)
        config = MultiJson.load gcloud_json
        config["configuration"]["properties"]["core"]["project"]
      rescue StandardError
        nil
      end

      private

      def interpret_options scope, options
        if scope.is_a? Hash
          options = scope
          scope = nil
        end
        return options.merge scope: scope if scope && !options[:scope]
        options
      end

      def service_account_env_vars?
        ([PRIVATE_KEY_VAR, CLIENT_EMAIL_VAR] - ENV.keys).empty? &&
          !ENV.to_h.fetch_values(PRIVATE_KEY_VAR, CLIENT_EMAIL_VAR).join(" ").empty?
      end

      def authorized_user_env_vars?
        ([CLIENT_ID_VAR, CLIENT_SECRET_VAR, REFRESH_TOKEN_VAR] - ENV.keys).empty? &&
          !ENV.to_h.fetch_values(CLIENT_ID_VAR, CLIENT_SECRET_VAR, REFRESH_TOKEN_VAR).join(" ").empty?
      end
    end
  end
end
