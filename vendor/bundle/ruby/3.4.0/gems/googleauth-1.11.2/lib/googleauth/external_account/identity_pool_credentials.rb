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

require "time"
require "googleauth/external_account/base_credentials"
require "googleauth/external_account/external_account_utils"

module Google
  # Module Auth provides classes that provide Google-specific authorization used to access Google APIs.
  module Auth
    module ExternalAccount
      # This module handles the retrieval of credentials from Google Cloud by utilizing the any 3PI
      # provider then exchanging the credentials for a short-lived Google Cloud access token.
      class IdentityPoolCredentials
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
          @credential_source_file = @credential_source[:file]
          @credential_source_url = @credential_source[:url]
          @credential_source_headers = @credential_source[:headers] || {}
          @credential_source_format = @credential_source[:format] || {}
          @credential_source_format_type = @credential_source_format[:type] || "text"
          validate_credential_source
        end

        # Implementation of BaseCredentials retrieve_subject_token!
        def retrieve_subject_token!
          content, resource_name = token_data
          if @credential_source_format_type == "text"
            token = content
          else
            begin
              response_data = MultiJson.load content, symbolize_keys: true
              token = response_data[@credential_source_field_name.to_sym]
            rescue StandardError
              raise "Unable to parse subject_token from JSON resource #{resource_name} " \
                    "using key #{@credential_source_field_name}"
            end
          end
          raise "Missing subject_token in the credential_source file/response." unless token
          token
        end

        private

        def validate_credential_source
          # `environment_id` is only supported in AWS or dedicated future external account credentials.
          unless @credential_source[:environment_id].nil?
            raise "Invalid Identity Pool credential_source field 'environment_id'"
          end
          unless ["json", "text"].include? @credential_source_format_type
            raise "Invalid credential_source format #{@credential_source_format_type}"
          end
          # for JSON types, get the required subject_token field name.
          @credential_source_field_name = @credential_source_format[:subject_token_field_name]
          if @credential_source_format_type == "json" && @credential_source_field_name.nil?
            raise "Missing subject_token_field_name for JSON credential_source format"
          end
          # check file or url must be fulfilled and mutually exclusiveness.
          if @credential_source_file && @credential_source_url
            raise "Ambiguous credential_source. 'file' is mutually exclusive with 'url'."
          end
          return unless (@credential_source_file || @credential_source_url).nil?
          raise "Missing credential_source. A 'file' or 'url' must be provided."
        end

        def token_data
          @credential_source_file.nil? ? url_data : file_data
        end

        def file_data
          raise "File #{@credential_source_file} was not found." unless File.exist? @credential_source_file
          content = File.read @credential_source_file, encoding: "utf-8"
          [content, @credential_source_file]
        end

        def url_data
          begin
            response = connection.get @credential_source_url do |req|
              req.headers.merge! @credential_source_headers
            end
          rescue Faraday::Error => e
            raise "Error retrieving from credential url: #{e}"
          end
          raise "Unable to retrieve Identity Pool subject token #{response.body}" unless response.success?
          [response.body, @credential_source_url]
        end
      end
    end
  end
end
