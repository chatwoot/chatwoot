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


require "googleauth"

module Google
  module Cloud
    module Storage
      ##
      # # Credentials
      #
      # Represents the authentication and authorization used to connect to the
      # Storage API.
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   keyfile = "/path/to/keyfile.json"
      #   creds = Google::Cloud::Storage::Credentials.new keyfile
      #
      #   storage = Google::Cloud::Storage.new(
      #     project_id: "my-project",
      #     credentials: creds
      #   )
      #
      #   storage.project_id #=> "my-project"
      #
      class Credentials < Google::Auth::Credentials
        SCOPE = ["https://www.googleapis.com/auth/devstorage.full_control"].freeze
        PATH_ENV_VARS = [
          "STORAGE_CREDENTIALS",
          "STORAGE_KEYFILE",
          "GOOGLE_CLOUD_CREDENTIALS",
          "GOOGLE_CLOUD_KEYFILE",
          "GCLOUD_KEYFILE"
        ].freeze
        JSON_ENV_VARS = [
          "STORAGE_CREDENTIALS_JSON",
          "STORAGE_KEYFILE_JSON",
          "GOOGLE_CLOUD_CREDENTIALS_JSON",
          "GOOGLE_CLOUD_KEYFILE_JSON",
          "GCLOUD_KEYFILE_JSON"
        ].freeze
        DEFAULT_PATHS = ["~/.config/gcloud/application_default_credentials.json"].freeze
      end
    end
  end
end
