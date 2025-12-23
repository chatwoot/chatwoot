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

require "open3"
require "time"
require "googleauth/external_account/base_credentials"
require "googleauth/external_account/external_account_utils"

module Google
  # Module Auth provides classes that provide Google-specific authorization used to access Google APIs.
  module Auth
    module ExternalAccount
      # This module handles the retrieval of credentials from Google Cloud by utilizing the any 3PI
      # provider then exchanging the credentials for a short-lived Google Cloud access token.
      class PluggableAuthCredentials
        # constant for pluggable auth enablement in environment variable.
        ENABLE_PLUGGABLE_ENV = "GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES".freeze
        EXECUTABLE_SUPPORTED_MAX_VERSION = 1
        EXECUTABLE_TIMEOUT_MILLIS_DEFAULT = 30 * 1000
        EXECUTABLE_TIMEOUT_MILLIS_LOWER_BOUND = 5 * 1000
        EXECUTABLE_TIMEOUT_MILLIS_UPPER_BOUND = 120 * 1000
        ID_TOKEN_TYPE = ["urn:ietf:params:oauth:token-type:jwt", "urn:ietf:params:oauth:token-type:id_token"].freeze

        include Google::Auth::ExternalAccount::BaseCredentials
        include Google::Auth::ExternalAccount::ExternalAccountUtils
        extend CredentialsLoader

        # Will always be nil, but method still gets used.
        attr_reader :client_id

        # Initialize from options map.
        #
        # @param [string] audience
        # @param [hash{symbol => value}] credential_source
        #     credential_source is a hash that contains either source file or url.
        #     credential_source_format is either text or json. To define how we parse the credential response.
        #
        def initialize options = {}
          base_setup options

          @audience = options[:audience]
          @credential_source = options[:credential_source] || {}
          @credential_source_executable = @credential_source[:executable]
          raise "Missing excutable source. An 'executable' must be provided" if @credential_source_executable.nil?
          @credential_source_executable_command = @credential_source_executable[:command]
          if @credential_source_executable_command.nil?
            raise "Missing command field. Executable command must be provided."
          end
          @credential_source_executable_timeout_millis = @credential_source_executable[:timeout_millis] ||
                                                         EXECUTABLE_TIMEOUT_MILLIS_DEFAULT
          if @credential_source_executable_timeout_millis < EXECUTABLE_TIMEOUT_MILLIS_LOWER_BOUND ||
             @credential_source_executable_timeout_millis > EXECUTABLE_TIMEOUT_MILLIS_UPPER_BOUND
            raise "Timeout must be between 5 and 120 seconds."
          end
          @credential_source_executable_output_file = @credential_source_executable[:output_file]
        end

        def retrieve_subject_token!
          unless ENV[ENABLE_PLUGGABLE_ENV] == "1"
            raise "Executables need to be explicitly allowed (set GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES to '1') " \
                  "to run."
          end
          # check output file first
          subject_token = load_subject_token_from_output_file
          return subject_token unless subject_token.nil?
          # environment variable injection
          env = inject_environment_variables
          output = subprocess_with_timeout env, @credential_source_executable_command,
                                           @credential_source_executable_timeout_millis
          response = MultiJson.load output, symbolize_keys: true
          parse_subject_token response
        end

        private

        def load_subject_token_from_output_file
          return nil if @credential_source_executable_output_file.nil?
          return nil unless File.exist? @credential_source_executable_output_file
          begin
            content = File.read @credential_source_executable_output_file, encoding: "utf-8"
            response = MultiJson.load content, symbolize_keys: true
          rescue StandardError
            return nil
          end
          begin
            subject_token = parse_subject_token response
          rescue StandardError => e
            return nil if e.message.match(/The token returned by the executable is expired/)
            raise e
          end
          subject_token
        end

        def parse_subject_token response
          validate_response_schema response
          unless response[:success]
            if response[:code].nil? || response[:message].nil?
              raise "Error code and message fields are required in the response."
            end
            raise "Executable returned unsuccessful response: code: #{response[:code]}, message: #{response[:message]}."
          end
          if response[:expiration_time] && response[:expiration_time] < Time.now.to_i
            raise "The token returned by the executable is expired."
          end
          raise "The executable response is missing the token_type field." if response[:token_type].nil?
          return response[:id_token] if ID_TOKEN_TYPE.include? response[:token_type]
          return response[:saml_response] if response[:token_type] == "urn:ietf:params:oauth:token-type:saml2"
          raise "Executable returned unsupported token type."
        end

        def validate_response_schema response
          raise "The executable response is missing the version field." if response[:version].nil?
          if response[:version] > EXECUTABLE_SUPPORTED_MAX_VERSION
            raise "Executable returned unsupported version #{response[:version]}."
          end
          raise "The executable response is missing the success field." if response[:success].nil?
        end

        def inject_environment_variables
          env = ENV.to_h
          env["GOOGLE_EXTERNAL_ACCOUNT_AUDIENCE"] = @audience
          env["GOOGLE_EXTERNAL_ACCOUNT_TOKEN_TYPE"] = @subject_token_type
          env["GOOGLE_EXTERNAL_ACCOUNT_INTERACTIVE"] = "0" # only non-interactive mode we support.
          unless @service_account_impersonation_url.nil?
            env["GOOGLE_EXTERNAL_ACCOUNT_IMPERSONATED_EMAIL"] = service_account_email
          end
          unless @credential_source_executable_output_file.nil?
            env["GOOGLE_EXTERNAL_ACCOUNT_OUTPUT_FILE"] = @credential_source_executable_output_file
          end
          env
        end

        def subprocess_with_timeout environment_vars, command, timeout_seconds
          Timeout.timeout timeout_seconds do
            output, error, status = Open3.capture3 environment_vars, command
            unless status.success?
              raise "Executable exited with non-zero return code #{status.exitstatus}. Error: #{output}, #{error}"
            end
            output
          end
        end
      end
    end
  end
end
