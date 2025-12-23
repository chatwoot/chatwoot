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


require "google/cloud/storage/version"
require "google/apis/storage_v1"
require "google/cloud/config"
require "digest"
require "mini_mime"
require "pathname"

module Google
  module Cloud
    module Storage
      ##
      # @private Represents the connection to Storage,
      # as well as expose the API calls.
      class Service
        ##
        # Alias to the Google Client API module
        API = Google::Apis::StorageV1

        # @private
        attr_accessor :project

        # @private
        attr_accessor :credentials

        # @private
        def universe_domain
          service.universe_domain
        end

        ##
        # Creates a new Service instance.
        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def initialize project, credentials, retries: nil,
                       timeout: nil, open_timeout: nil, read_timeout: nil,
                       send_timeout: nil, host: nil, quota_project: nil,
                       max_elapsed_time: nil, base_interval: nil, max_interval: nil,
                       multiplier: nil, upload_chunk_size: nil, universe_domain: nil
          host ||= Google::Cloud::Storage.configure.endpoint
          @project = project
          @credentials = credentials
          @service = API::StorageService.new
          @service.client_options.application_name    = "gcloud-ruby"
          @service.client_options.application_version = \
            Google::Cloud::Storage::VERSION
          @service.client_options.open_timeout_sec = (open_timeout || timeout)
          @service.client_options.read_timeout_sec = (read_timeout || timeout)
          @service.client_options.send_timeout_sec = (send_timeout || timeout)
          @service.client_options.transparent_gzip_decompression = false
          @service.request_options.retries = retries || 3
          @service.request_options.header ||= {}
          @service.request_options.header["x-goog-api-client"] = \
            "gl-ruby/#{RUBY_VERSION} gccl/#{Google::Cloud::Storage::VERSION}"
          @service.request_options.header["Accept-Encoding"] = "gzip"
          @service.request_options.quota_project = quota_project if quota_project
          @service.request_options.max_elapsed_time = max_elapsed_time if max_elapsed_time
          @service.request_options.base_interval = base_interval if base_interval
          @service.request_options.max_interval = max_interval if max_interval
          @service.request_options.multiplier = multiplier if multiplier
          @service.request_options.add_invocation_id_header = true
          @service.request_options.upload_chunk_size = upload_chunk_size if upload_chunk_size
          @service.authorization = @credentials.client if @credentials
          @service.root_url = host if host
          @service.universe_domain = universe_domain || Google::Cloud::Storage.configure.universe_domain
          begin
            @service.verify_universe_domain!
          rescue Google::Apis::UniverseDomainError => e
            # TODO: Create a Google::Cloud::Error subclass for this.
            raise Google::Cloud::Error, e.message
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def service
          return mocked_service if mocked_service
          @service
        end
        attr_accessor :mocked_service

        def project_service_account
          service.get_project_service_account project
        end

        ##
        # Retrieves a list of buckets for the given project.
        def list_buckets prefix: nil, token: nil, max: nil, user_project: nil, options: {}
          execute do
            service.list_buckets \
              @project, prefix: prefix, page_token: token, max_results: max,
                        user_project: user_project(user_project), options: options
          end
        end

        ##
        # Retrieves bucket by name.
        # Returns Google::Apis::StorageV1::Bucket.
        def get_bucket bucket_name,
                       if_metageneration_match: nil,
                       if_metageneration_not_match: nil,
                       user_project: nil,
                       options: {}
          execute do
            service.get_bucket bucket_name,
                               if_metageneration_match: if_metageneration_match,
                               if_metageneration_not_match: if_metageneration_not_match,
                               user_project: user_project(user_project),
                               options: options
          end
        end

        ##
        # Creates a new bucket.
        # Returns Google::Apis::StorageV1::Bucket.
        def insert_bucket bucket_gapi, acl: nil, default_acl: nil,
                          user_project: nil, enable_object_retention: nil,
                          options: {}
          execute do
            service.insert_bucket \
              @project, bucket_gapi,
              predefined_acl: acl,
              predefined_default_object_acl: default_acl,
              user_project: user_project(user_project),
              options: options,
              enable_object_retention: enable_object_retention
          end
        end

        ##
        # Updates a bucket, including its ACL metadata.
        def patch_bucket bucket_name,
                         bucket_gapi = nil,
                         predefined_acl: nil,
                         predefined_default_acl: nil,
                         if_metageneration_match: nil,
                         if_metageneration_not_match: nil,
                         user_project: nil,
                         options: {}
          bucket_gapi ||= Google::Apis::StorageV1::Bucket.new
          bucket_gapi.acl = [] if predefined_acl
          bucket_gapi.default_object_acl = [] if predefined_default_acl

          if options[:retries].nil?
            is_idempotent = retry? if_metageneration_match: if_metageneration_match
            options = is_idempotent ? {} : { retries: 0 }
          end

          execute do
            service.patch_bucket bucket_name,
                                 bucket_gapi,
                                 predefined_acl: predefined_acl,
                                 predefined_default_object_acl: predefined_default_acl,
                                 if_metageneration_match: if_metageneration_match,
                                 if_metageneration_not_match: if_metageneration_not_match,
                                 user_project: user_project(user_project),
                                 options: options
          end
        end

        ##
        # Permanently deletes an empty bucket.
        def delete_bucket bucket_name,
                          if_metageneration_match: nil,
                          if_metageneration_not_match: nil,
                          user_project: nil,
                          options: {}
          execute do
            service.delete_bucket bucket_name,
                                  if_metageneration_match: if_metageneration_match,
                                  if_metageneration_not_match: if_metageneration_not_match,
                                  user_project: user_project(user_project),
                                  options: options
          end
        end

        ##
        # Locks retention policy on a bucket.
        def lock_bucket_retention_policy bucket_name, metageneration,
                                         user_project: nil,
                                         options: {}
          execute do
            service.lock_bucket_retention_policy \
              bucket_name, metageneration,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves a list of ACLs for the given bucket.
        def list_bucket_acls bucket_name, user_project: nil, options: {}
          execute do
            service.list_bucket_access_controls \
              bucket_name, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Creates a new bucket ACL.
        def insert_bucket_acl bucket_name, entity, role, user_project: nil, options: {}
          params = { entity: entity, role: role }.delete_if { |_k, v| v.nil? }
          new_acl = Google::Apis::StorageV1::BucketAccessControl.new(**params)
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          execute do
            service.insert_bucket_access_control \
              bucket_name, new_acl, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Permanently deletes a bucket ACL.
        def delete_bucket_acl bucket_name, entity, user_project: nil, options: {}
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          execute do
            service.delete_bucket_access_control \
              bucket_name, entity, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves a list of default ACLs for the given bucket.
        def list_default_acls bucket_name, user_project: nil, options: {}
          execute do
            service.list_default_object_access_controls \
              bucket_name, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Creates a new default ACL.
        def insert_default_acl bucket_name, entity, role, user_project: nil, options: {}
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          param = { entity: entity, role: role }.delete_if { |_k, v| v.nil? }
          new_acl = Google::Apis::StorageV1::ObjectAccessControl.new(**param)
          execute do
            service.insert_default_object_access_control \
              bucket_name, new_acl, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Permanently deletes a default ACL.
        def delete_default_acl bucket_name, entity, user_project: nil, options: {}
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          execute do
            service.delete_default_object_access_control \
              bucket_name, entity, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Returns Google::Apis::StorageV1::Policy
        def get_bucket_policy bucket_name, requested_policy_version: nil, user_project: nil,
                              options: {}
          # get_bucket_iam_policy(bucket, fields: nil, quota_user: nil,
          #                               user_ip: nil, options: nil)
          execute do
            service.get_bucket_iam_policy bucket_name, options_requested_policy_version: requested_policy_version,
                                                       user_project: user_project(user_project), options: options
          end
        end

        ##
        # Returns Google::Apis::StorageV1::Policy
        def set_bucket_policy bucket_name, new_policy, user_project: nil, options: {}
          execute do
            service.set_bucket_iam_policy \
              bucket_name, new_policy, user_project: user_project(user_project), options: options
          end
        end

        ##
        # Returns Google::Apis::StorageV1::TestIamPermissionsResponse
        def test_bucket_permissions bucket_name, permissions, user_project: nil, options: {}
          execute do
            service.test_bucket_iam_permissions \
              bucket_name, permissions, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves a list of Pub/Sub notification subscriptions for a bucket.
        def list_notifications bucket_name, user_project: nil, options: {}
          execute do
            service.list_notifications bucket_name,
                                       user_project: user_project(user_project),
                                       options: options
          end
        end

        ##
        # Creates a new Pub/Sub notification subscription for a bucket.
        def insert_notification bucket_name, topic_name, custom_attrs: nil,
                                event_types: nil, prefix: nil, payload: nil,
                                user_project: nil, options: {}
          params =
            { custom_attributes: custom_attrs,
              event_types: event_types(event_types),
              object_name_prefix: prefix,
              payload_format: payload_format(payload),
              topic: topic_path(topic_name) }.delete_if { |_k, v| v.nil? }
          new_notification = Google::Apis::StorageV1::Notification.new(**params)

          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end

          execute do
            service.insert_notification \
              bucket_name, new_notification,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves a Pub/Sub notification subscription for a bucket.
        def get_notification bucket_name, notification_id, user_project: nil, options: {}
          execute do
            service.get_notification bucket_name, notification_id,
                                     user_project: user_project(user_project),
                                     options: options
          end
        end

        ##
        # Deletes a new Pub/Sub notification subscription for a bucket.
        def delete_notification bucket_name, notification_id, user_project: nil, options: {}
          execute do
            service.delete_notification bucket_name, notification_id,
                                        user_project: user_project(user_project),
                                        options: options
          end
        end

        ##
        # Retrieves a list of files matching the criteria.
        def list_files bucket_name, delimiter: nil, max: nil, token: nil,
                       prefix: nil, versions: nil, user_project: nil,
                       match_glob: nil, include_folders_as_prefixes: nil,
                       soft_deleted: nil, options: {}
          execute do
            service.list_objects \
              bucket_name, delimiter: delimiter, max_results: max,
                           page_token: token, prefix: prefix,
                           versions: versions,
                           user_project: user_project(user_project),
                           match_glob: match_glob,
                           include_folders_as_prefixes: include_folders_as_prefixes,
                           soft_deleted: soft_deleted,
                           options: options
          end
        end

        ##
        # Inserts a new file for the given bucket
        def insert_file bucket_name,
                        source,
                        path = nil,
                        acl: nil,
                        cache_control: nil,
                        content_disposition: nil,
                        content_encoding: nil,
                        content_language: nil,
                        content_type: nil,
                        custom_time: nil,
                        crc32c: nil,
                        md5: nil,
                        metadata: nil,
                        storage_class: nil,
                        key: nil,
                        kms_key: nil,
                        temporary_hold: nil,
                        event_based_hold: nil,
                        if_generation_match: nil,
                        if_generation_not_match: nil,
                        if_metageneration_match: nil,
                        if_metageneration_not_match: nil,
                        user_project: nil,
                        options: {}
          params = {
            cache_control: cache_control,
            content_type: content_type,
            custom_time: custom_time,
            content_disposition: content_disposition,
            md5_hash: md5,
            content_encoding: content_encoding,
            crc32c: crc32c,
            content_language: content_language,
            metadata: metadata,
            storage_class: storage_class,
            temporary_hold: temporary_hold,
            event_based_hold: event_based_hold
          }.delete_if { |_k, v| v.nil? }
          file_obj = Google::Apis::StorageV1::Object.new(**params)
          content_type ||= mime_type_for(path || Pathname(source).to_path)

          if options[:retries].nil?
            is_idempotent = retry? if_generation_match: if_generation_match
            options = is_idempotent ? key_options(key) : key_options(key).merge(retries: 0)
          else
            options = key_options(key).merge options
          end

          execute do
            service.insert_object bucket_name,
                                  file_obj,
                                  name: path,
                                  predefined_acl: acl,
                                  upload_source: source,
                                  content_encoding: content_encoding,
                                  content_type: content_type,
                                  if_generation_match: if_generation_match,
                                  if_generation_not_match: if_generation_not_match,
                                  if_metageneration_match: if_metageneration_match,
                                  if_metageneration_not_match: if_metageneration_not_match,
                                  kms_key_name: kms_key,
                                  user_project: user_project(user_project),
                                  options: options
          end
        end

        ##
        # Retrieves an object or its metadata.
        def get_file bucket_name,
                     file_path,
                     generation: nil,
                     if_generation_match: nil,
                     if_generation_not_match: nil,
                     if_metageneration_match: nil,
                     if_metageneration_not_match: nil,
                     key: nil,
                     user_project: nil,
                     soft_deleted: nil,
                     options: {}
          execute do
            service.get_object \
              bucket_name, file_path,
              generation: generation,
              if_generation_match: if_generation_match,
              if_generation_not_match: if_generation_not_match,
              if_metageneration_match: if_metageneration_match,
              if_metageneration_not_match: if_metageneration_not_match,
              user_project: user_project(user_project),
              soft_deleted: soft_deleted,
              options: key_options(key).merge(options)
          end
        end

        ## Rewrite a file from source bucket/object to a
        # destination bucket/object.
        def rewrite_file source_bucket_name,
                         source_file_path,
                         destination_bucket_name,
                         destination_file_path,
                         file_gapi = nil,
                         source_key: nil,
                         destination_key: nil,
                         destination_kms_key: nil,
                         acl: nil,
                         generation: nil,
                         if_generation_match: nil,
                         if_generation_not_match: nil,
                         if_metageneration_match: nil,
                         if_metageneration_not_match: nil,
                         if_source_generation_match: nil,
                         if_source_generation_not_match: nil,
                         if_source_metageneration_match: nil,
                         if_source_metageneration_not_match: nil,
                         token: nil,
                         user_project: nil,
                         options: {}
          key_options = rewrite_key_options source_key, destination_key

          if options[:retries].nil?
            is_idempotent = retry? if_generation_match: if_generation_match
            options = is_idempotent ? key_options : key_options.merge(retries: 0)
          else
            options = key_options.merge options
          end

          execute do
            service.rewrite_object source_bucket_name,
                                   source_file_path,
                                   destination_bucket_name,
                                   destination_file_path,
                                   file_gapi,
                                   destination_kms_key_name: destination_kms_key,
                                   destination_predefined_acl: acl,
                                   source_generation: generation,
                                   if_generation_match: if_generation_match,
                                   if_generation_not_match: if_generation_not_match,
                                   if_metageneration_match: if_metageneration_match,
                                   if_metageneration_not_match: if_metageneration_not_match,
                                   if_source_generation_match: if_source_generation_match,
                                   if_source_generation_not_match: if_source_generation_not_match,
                                   if_source_metageneration_match: if_source_metageneration_match,
                                   if_source_metageneration_not_match: if_source_metageneration_not_match,
                                   rewrite_token: token,
                                   user_project: user_project(user_project),
                                   options: options
          end
        end

        ## Copy a file from source bucket/object to a
        # destination bucket/object.
        def compose_file bucket_name,
                         source_files,
                         destination_path,
                         destination_gapi,
                         acl: nil,
                         key: nil,
                         if_source_generation_match: nil,
                         if_generation_match: nil,
                         if_metageneration_match: nil,
                         user_project: nil,
                         options: {}

          source_objects = compose_file_source_objects source_files, if_source_generation_match
          compose_req = Google::Apis::StorageV1::ComposeRequest.new source_objects: source_objects,
                                                                    destination: destination_gapi

          if options[:retries].nil?
            is_idempotent = retry? if_generation_match: if_generation_match
            options = is_idempotent ? key_options(key) : key_options(key).merge(retries: 0)
          else
            options = key_options.merge options
          end

          execute do
            service.compose_object bucket_name,
                                   destination_path,
                                   compose_req,
                                   destination_predefined_acl: acl,
                                   if_generation_match: if_generation_match,
                                   if_metageneration_match: if_metageneration_match,
                                   user_project: user_project(user_project),
                                   options: options
          end
        end

        ##
        # Download contents of a file.
        #
        # Returns a two-element array containing:
        #   * The IO object that is the usual return type of
        #     StorageService#get_object (for downloads)
        #   * The `http_resp` accessed via the monkey-patches of
        #     Apis::StorageV1::StorageService and Apis::Core::DownloadCommand at
        #     the end of this file.
        def download_file bucket_name, file_path, target_path, generation: nil,
                          key: nil, range: nil, user_project: nil, options: {}
          options = key_options(key).merge(options)
          options = range_header options, range

          execute do
            service.get_object \
              bucket_name, file_path,
              download_dest: target_path, generation: generation,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Updates a file's metadata.
        def patch_file bucket_name,
                       file_path,
                       file_gapi = nil,
                       generation: nil,
                       if_generation_match: nil,
                       if_generation_not_match: nil,
                       if_metageneration_match: nil,
                       if_metageneration_not_match: nil,
                       predefined_acl: nil,
                       user_project: nil,
                       override_unlocked_retention: nil,
                       options: {}
          file_gapi ||= Google::Apis::StorageV1::Object.new

          if options[:retries].nil?
            is_idempotent = retry? if_metageneration_match: if_metageneration_match
            options = is_idempotent ? {} : { retries: 0 }
          end

          execute do
            service.patch_object bucket_name,
                                 file_path,
                                 file_gapi,
                                 generation: generation,
                                 if_generation_match: if_generation_match,
                                 if_generation_not_match: if_generation_not_match,
                                 if_metageneration_match: if_metageneration_match,
                                 if_metageneration_not_match: if_metageneration_not_match,
                                 predefined_acl: predefined_acl,
                                 user_project: user_project(user_project),
                                 override_unlocked_retention: override_unlocked_retention,
                                 options: options
          end
        end

        ##
        # Permanently deletes a file.
        def delete_file bucket_name,
                        file_path,
                        generation: nil,
                        if_generation_match: nil,
                        if_generation_not_match: nil,
                        if_metageneration_match: nil,
                        if_metageneration_not_match: nil,
                        user_project: nil,
                        options: {}

          if options[:retries].nil?
            is_idempotent = retry? generation: generation, if_generation_match: if_generation_match
            options = is_idempotent ? {} : { retries: 0 }
          end

          execute do
            service.delete_object bucket_name, file_path,
                                  generation: generation,
                                  if_generation_match: if_generation_match,
                                  if_generation_not_match: if_generation_not_match,
                                  if_metageneration_match: if_metageneration_match,
                                  if_metageneration_not_match: if_metageneration_not_match,
                                  user_project: user_project(user_project),
                                  options: options
          end
        end

        ##
        # Restores a soft-deleted object.
        def restore_file bucket_name,
                         file_path,
                         generation,
                         copy_source_acl: nil,
                         if_generation_match: nil,
                         if_generation_not_match: nil,
                         if_metageneration_match: nil,
                         if_metageneration_not_match: nil,
                         projection: nil,
                         user_project: nil,
                         fields: nil,
                         options: {}

          if options[:retries].nil?
            is_idempotent = retry? generation: generation, if_generation_match: if_generation_match
            options = is_idempotent ? {} : { retries: 0 }
          end

          execute do
            service.restore_object bucket_name, file_path, generation,
                                   copy_source_acl: copy_source_acl,
                                   if_generation_match: if_generation_match,
                                   if_generation_not_match: if_generation_not_match,
                                   if_metageneration_match: if_metageneration_match,
                                   if_metageneration_not_match: if_metageneration_not_match,
                                   projection: projection,
                                   user_project: user_project(user_project),
                                   fields: fields,
                                   options: options
          end
        end

        ##
        # Retrieves a list of ACLs for the given file.
        def list_file_acls bucket_name, file_name, user_project: nil, options: {}
          execute do
            service.list_object_access_controls \
              bucket_name, file_name, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Creates a new file ACL.
        def insert_file_acl bucket_name, file_name, entity, role,
                            generation: nil, user_project: nil,
                            options: {}
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          params = { entity: entity, role: role }.delete_if { |_k, v| v.nil? }
          new_acl = Google::Apis::StorageV1::ObjectAccessControl.new(**params)
          execute do
            service.insert_object_access_control \
              bucket_name, file_name, new_acl,
              generation: generation, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Permanently deletes a file ACL.
        def delete_file_acl bucket_name, file_name, entity, generation: nil,
                            user_project: nil, options: {}
          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end
          execute do
            service.delete_object_access_control \
              bucket_name, file_name, entity,
              generation: generation, user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Creates a new HMAC key for the specified service account.
        # Returns Google::Apis::StorageV1::HmacKey.
        def create_hmac_key service_account_email, project_id: nil,
                            user_project: nil, options: {}

          if options[:retries].nil?
            options = options.merge({ retries: 0 })
          end

          execute do
            service.create_project_hmac_key \
              (project_id || @project), service_account_email,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Deletes an HMAC key. Key must be in the INACTIVE state.
        def delete_hmac_key access_id, project_id: nil, user_project: nil,
                            options: {}
          execute do
            service.delete_project_hmac_key \
              (project_id || @project), access_id,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves an HMAC key's metadata.
        # Returns Google::Apis::StorageV1::HmacKeyMetadata.
        def get_hmac_key access_id, project_id: nil, user_project: nil,
                         options: {}
          execute do
            service.get_project_hmac_key \
              (project_id || @project), access_id,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Retrieves a list of HMAC key metadata matching the criteria.
        # Returns Google::Apis::StorageV1::HmacKeysMetadata.
        def list_hmac_keys max: nil, token: nil, service_account_email: nil,
                           project_id: nil, show_deleted_keys: nil,
                           user_project: nil, options: {}
          execute do
            service.list_project_hmac_keys \
              (project_id || @project),
              max_results: max, page_token: token,
              service_account_email: service_account_email,
              show_deleted_keys: show_deleted_keys,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Updates the state of an HMAC key. See the HMAC Key resource descriptor
        # for valid states.
        # Returns Google::Apis::StorageV1::HmacKeyMetadata.
        def update_hmac_key access_id, hmac_key_metadata_object,
                            project_id: nil, user_project: nil,
                            options: {}
          execute do
            service.update_project_hmac_key \
              (project_id || @project), access_id, hmac_key_metadata_object,
              user_project: user_project(user_project),
              options: options
          end
        end

        ##
        # Updates a bucket, including its ACL metadata.
        def update_bucket bucket_name,
                          bucket_gapi = nil,
                          predefined_acl: nil,
                          predefined_default_acl: nil,
                          if_metageneration_match: nil,
                          if_metageneration_not_match: nil,
                          user_project: nil,
                          options: {}
          bucket_gapi ||= Google::Apis::StorageV1::Bucket.new
          bucket_gapi.acl = [] if predefined_acl
          bucket_gapi.default_object_acl = [] if predefined_default_acl

          if options[:retries].nil?
            is_idempotent = retry? if_metageneration_match: if_metageneration_match
            options = is_idempotent ? {} : { retries: 0 }
          end

          execute do
            service.update_bucket bucket_name,
                                  bucket_gapi,
                                  predefined_acl: predefined_acl,
                                  predefined_default_object_acl: predefined_default_acl,
                                  if_metageneration_match: if_metageneration_match,
                                  if_metageneration_not_match: if_metageneration_not_match,
                                  user_project: user_project(user_project),
                                  options: options
          end
        end

        ##
        # Retrieves the mime-type for a file path.
        # An empty string is returned if no mime-type can be found.
        def mime_type_for path
          mime_type = MiniMime.lookup_by_filename path
          return "" if mime_type.nil?
          mime_type.content_type
        end

        # @private
        def inspect
          "#{self.class}(#{@project})"
        end

        ##
        # Add custom Google extension headers to the requests that use the signed URLs.
        def add_custom_headers headers
          @service.request_options.header.merge! headers
        end

        ##
        # Add custom Google extension header to the requests that use the signed URLs.
        def add_custom_header header_name, header_value
          @service.request_options.header[header_name] = header_value
        end

        protected

        def user_project user_project
          return nil unless user_project # nil or false get nil
          return @project if user_project == true # handle the true  condition
          String(user_project) # convert the value to a string
        end

        def key_options key
          options = {}
          encryption_key_headers options, key if key
          options
        end

        def rewrite_key_options source_key, destination_key
          options = {}
          if source_key
            encryption_key_headers options, source_key, copy_source: true
          end
          encryption_key_headers options, destination_key if destination_key
          options
        end

        # @private
        # @param copy_source If true, header names are those for source object
        #   in rewrite request. If false, the header names are for use with any
        #   method supporting customer-supplied encryption keys.
        #   See https://cloud.google.com/storage/docs/encryption#request
        def encryption_key_headers options, key, copy_source: false
          source = copy_source ? "copy-source-" : ""
          key_sha256 = Digest::SHA256.digest key
          headers = (options[:header] ||= {})
          headers["x-goog-#{source}encryption-algorithm"] = "AES256"
          headers["x-goog-#{source}encryption-key"] = Base64.strict_encode64 key
          headers["x-goog-#{source}encryption-key-sha256"] = \
            Base64.strict_encode64 key_sha256
          options
        end

        def range_header options, range
          case range
          when Range
            options[:header] ||= {}
            options[:header]["Range"] = "bytes=#{range.min}-#{range.max}"
          when String
            options[:header] ||= {}
            options[:header]["Range"] = range
          end

          options
        end

        def topic_path topic_name
          return topic_name if topic_name.to_s.include? "/"
          "//pubsub.googleapis.com/projects/#{project}/topics/#{topic_name}"
        end

        # Pub/Sub notification subscription event_types
        def event_types str_or_arr
          Array(str_or_arr).map { |x| event_type x } if str_or_arr
        end

        # Pub/Sub notification subscription event_types
        def event_type str
          { "object_finalize" => "OBJECT_FINALIZE",
            "finalize" => "OBJECT_FINALIZE",
            "create" => "OBJECT_FINALIZE",
            "object_metadata_update" => "OBJECT_METADATA_UPDATE",
            "object_update" => "OBJECT_METADATA_UPDATE",
            "metadata_update" => "OBJECT_METADATA_UPDATE",
            "update" => "OBJECT_METADATA_UPDATE",
            "object_delete" => "OBJECT_DELETE",
            "delete" => "OBJECT_DELETE",
            "object_archive" => "OBJECT_ARCHIVE",
            "archive" => "OBJECT_ARCHIVE" }[str.to_s.downcase]
        end

        # Pub/Sub notification subscription payload_format
        # Defaults to "JSON_API_V1"
        def payload_format str_or_bool
          return "JSON_API_V1" if str_or_bool.nil?
          { "json_api_v1" => "JSON_API_V1",
            "json" => "JSON_API_V1",
            "true" => "JSON_API_V1",
            "none" => "NONE",
            "false" => "NONE" }[str_or_bool.to_s.downcase]
        end

        def compose_file_source_objects source_files, if_source_generation_match
          source_objects = source_files.map do |file|
            if file.is_a? Google::Cloud::Storage::File
              Google::Apis::StorageV1::ComposeRequest::SourceObject.new \
                name: file.name,
                generation: file.generation
            else
              Google::Apis::StorageV1::ComposeRequest::SourceObject.new \
                name: file
            end
          end
          return source_objects unless if_source_generation_match
          if source_files.count != if_source_generation_match.count
            raise ArgumentError, "if provided, if_source_generation_match length must match sources length"
          end
          if_source_generation_match.each_with_index do |generation, i|
            next unless generation
            object_preconditions = Google::Apis::StorageV1::ComposeRequest::SourceObject::ObjectPreconditions.new(
              if_generation_match: generation
            )
            source_objects[i].object_preconditions = object_preconditions
          end
          source_objects
        end

        def execute
          yield
        rescue Google::Apis::Error => e
          raise Google::Cloud::Error.from_error(e)
        end

        def retry? query_params
          query_params.any? { |_key, val| !val.nil? }
        end
      end
    end
  end
end
