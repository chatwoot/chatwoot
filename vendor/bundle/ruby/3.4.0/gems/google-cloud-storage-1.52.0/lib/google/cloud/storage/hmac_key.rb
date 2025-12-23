# Copyright 2019 Google LLC
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


require "google/cloud/storage/hmac_key/list"

module Google
  module Cloud
    module Storage
      ##
      # # HmacKey
      #
      # Represents the metadata for an HMAC key, and also includes the key's
      # secret if returned by the {Project#create_hmac_key} creation method.
      #
      # @see https://cloud.google.com/storage/docs/migrating#migration-simple
      #   Migrating from Amazon S3 to Cloud Storage - Simple migration
      #
      # @attr_reader [String, nil] secret HMAC secret key material, or `nil` if
      #   the key was not returned by the {Project#create_hmac_key} creation
      #   method.
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #
      #   service_account_email = "my_account@developer.gserviceaccount.com"
      #   hmac_key = storage.create_hmac_key service_account_email
      #   hmac_key.secret # ...
      #
      #   hmac_key = storage.hmac_key hmac_key.access_id
      #   hmac_key.secret # nil
      #
      #   hmac_key.inactive!
      #   hmac_key.delete
      #
      class HmacKey
        ##
        # @private The Connection object.
        attr_accessor :service

        ##
        # @private The Google API Client object.
        attr_accessor :gapi

        ##
        # @private A boolean value or a project ID string to indicate the
        # project to be billed for operations.
        attr_accessor :user_project

        attr_reader :secret

        ##
        # @private Creates an HmacKey object.
        def initialize
          @bucket = nil
          @service = nil
          @gapi = nil
          @user_project = nil
        end

        ##
        # The ID of the HMAC Key.
        #
        # @return [String]
        #
        def access_id
          @gapi.access_id
        end

        ##
        # A URL that can be used to access the HMAC key using the REST API.
        #
        # @return [String]
        #
        def api_url
          @gapi.self_link
        end

        ##
        # Creation time of the HMAC key.
        #
        # @return [String]
        #
        def created_at
          @gapi.time_created
        end

        ##
        # HTTP 1.1 Entity tag for the HMAC key.
        #
        # @return [String]
        #
        def etag
          @gapi.etag
        end

        ##
        # The ID of the HMAC key, including the Project ID and the Access ID.
        #
        # @return [String]
        #
        def id
          @gapi.id
        end

        ##
        # Project ID owning the service account to which the key authenticates.
        #
        # @return [String]
        #
        def project_id
          @gapi.project_id
        end

        ##
        # The email address of the key's associated service account.
        #
        # @return [String]
        #
        def service_account_email
          @gapi.service_account_email
        end

        ##
        # The state of the key. Can be one of `ACTIVE`, `INACTIVE`, or
        # `DELETED`.
        #
        # @return [String]
        #
        def state
          @gapi.state
        end

        ##
        # Last modification time of the HMAC key metadata.
        #
        # @return [String]
        #
        def updated_at
          @gapi.updated
        end

        ##
        # Whether the state of the HMAC key is `ACTIVE`.
        #
        # @return [Boolean]
        #
        def active?
          state == "ACTIVE"
        end

        ##
        # Updates the state of the HMAC key to `ACTIVE`.
        #
        # @return [Google::Cloud::Storage::HmacKey] Returns the HMAC key for
        #   method chaining.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   hmac_key = storage.hmac_keys.first
        #
        #   hmac_key.active!
        #   hmac_key.state # "ACTIVE"
        #
        def active!
          put_gapi! "ACTIVE"
          self
        end

        ##
        # Whether the state of the HMAC key is `INACTIVE`.
        #
        # @return [Boolean]
        #
        def inactive?
          state == "INACTIVE"
        end

        ##
        # Updates the state of the HMAC key to `INACTIVE`.
        #
        # @return [Google::Cloud::Storage::HmacKey] Returns the HMAC key for
        #   method chaining.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   hmac_key = storage.hmac_keys.first
        #
        #   hmac_key.inactive!
        #   hmac_key.state # "INACTIVE"
        #
        def inactive!
          put_gapi! "INACTIVE"
          self
        end

        ##
        # Whether the state of the HMAC key is `DELETED`.
        #
        # @return [Boolean]
        #
        def deleted?
          state == "DELETED"
        end

        ##
        # Deletes the HMAC key, and loads the new state of the HMAC key,
        # which will be `DELETED`.
        #
        # The API call to delete the HMAC key may be retried under certain
        # conditions. See {Google::Cloud#storage} to control this behavior.
        #
        # @return [Google::Cloud::Storage::HmacKey] Returns the HMAC key for
        #   method chaining.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   hmac_key = storage.hmac_keys.first
        #
        #   hmac_key.inactive!.delete!
        #
        def delete!
          ensure_service!
          @service.delete_hmac_key access_id,
                                   project_id: project_id,
                                   user_project: @user_project
          @gapi = @service.get_hmac_key access_id, project_id: project_id,
                                                   user_project: @user_project
          self
        end
        alias delete delete!

        ##
        # Reloads the HMAC key with current data from the Storage service.
        #
        def reload!
          ensure_service!
          @gapi = service.get_hmac_key access_id, project_id: project_id,
                                                  user_project: user_project
          self
        end
        alias refresh! reload!

        ##
        # @private New HmacKey from a Google::Apis::StorageV1::HmacKey object.
        #
        # @param [Google::Apis::StorageV1::HmacKey] gapi
        #
        #
        def self.from_gapi gapi, service, user_project: nil
          hmac_key = from_gapi_metadata gapi.metadata,
                                        service,
                                        user_project: user_project
          hmac_key.tap do |f|
            f.instance_variable_set :@secret, gapi.secret
          end
        end

        ##
        # @private New HmacKey from a Google::Apis::StorageV1::HmacKeyMetadata
        # object.
        #
        # @param [Google::Apis::StorageV1::HmacKeyMetadata] gapi
        #
        #
        def self.from_gapi_metadata gapi, service, user_project: nil
          new.tap do |f|
            f.gapi = gapi
            f.service = service
            f.user_project = user_project
          end
        end

        protected

        ##
        # Raise an error unless an active service is available.
        def ensure_service!
          raise "Must have active connection" unless service
        end

        def put_gapi! new_state
          ensure_service!
          put_gapi = @gapi.dup
          put_gapi.state = new_state
          @gapi = service.update_hmac_key access_id, put_gapi,
                                          project_id: project_id,
                                          user_project: @user_project
          self
        end
      end
    end
  end
end
