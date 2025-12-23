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


require "google/cloud/storage/convert"
require "google/cloud/storage/file/acl"
require "google/cloud/storage/file/list"
require "google/cloud/storage/file/verifier"
require "google/cloud/storage/file/signer_v2"
require "google/cloud/storage/file/signer_v4"
require "zlib"

module Google
  module Cloud
    module Storage
      GOOGLEAPIS_URL = "https://storage.googleapis.com".freeze

      ##
      # # File
      #
      # Represents a File
      # ([Object](https://cloud.google.com/storage/docs/json_api/v1/objects))
      # that belongs to a {Bucket}. Files (Objects) are the individual pieces of
      # data that you store in Google Cloud Storage. A file can be up to 5 TB in
      # size. Files have two components: data and metadata. The data component
      # is the data from an external file or other data source that you want to
      # store in Google Cloud Storage. The metadata component is a collection of
      # name-value pairs that describe various qualities of the data.
      #
      # @see https://cloud.google.com/storage/docs/concepts-techniques Concepts
      #   and Techniques
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #
      #   bucket = storage.bucket "my-bucket"
      #
      #   file = bucket.file "path/to/my-file.ext"
      #   file.download "path/to/downloaded/file.ext"
      #
      # @example Download a public file with an unauthenticated client:
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.anonymous
      #
      #   bucket = storage.bucket "public-bucket", skip_lookup: true
      #   file = bucket.file "path/to/public-file.ext", skip_lookup: true
      #
      #   downloaded = file.download
      #   downloaded.rewind
      #   downloaded.read #=> "Hello world!"
      #
      class File
        include Convert
        ##
        # @private The Connection object.
        attr_accessor :service

        ##
        # If this attribute is set to `true`, transit costs for operations on
        # the file will be billed to the current project for this client. (See
        # {Project#project} for the ID of the current project.) If this
        # attribute is set to a project ID, and that project is authorized for
        # the currently authenticated service account, transit costs will be
        # billed to that project. This attribute is required with requester
        # pays-enabled buckets. The default is `nil`.
        #
        # In general, this attribute should be set when first retrieving the
        # owning bucket by providing the `user_project` option to
        # {Project#bucket} or {Project#buckets}.
        #
        # See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
        #
        # @example Setting a non-default project:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "other-project-bucket", user_project: true
        #   file = bucket.file "path/to/file.ext" # Billed to current project
        #   file.user_project = "my-other-project"
        #   file.download "file.ext" # Billed to "my-other-project"
        #
        attr_accessor :user_project

        ##
        # @private The Google API Client object.
        attr_accessor :gapi

        ##
        # @private Create an empty File object.
        def initialize
          @service = nil
          @gapi = Google::Apis::StorageV1::Object.new
          @user_project = nil
        end

        ##
        # The kind of item this is.
        # For files, this is always storage#object.
        #
        # @return [String]
        #
        def kind
          @gapi.kind
        end

        ##
        # The ID of the file.
        #
        # @return [String]
        #
        def id
          @gapi.id
        end

        ##
        # The name of this file.
        #
        # @return [String]
        #
        def name
          @gapi.name
        end

        ##
        # The name of the {Bucket} containing this file.
        #
        # @return [String]
        #
        def bucket
          @gapi.bucket
        end

        ##
        # The content generation of this file.
        # Used for object versioning.
        #
        # @return [Fixnum]
        #
        def generation
          @gapi.generation
        end

        ##
        # The version of the metadata for this file at this generation.
        # Used for preconditions and for detecting changes in metadata.
        # A metageneration number is only meaningful in the context of a
        # particular generation of a particular file.
        #
        # @return [Fixnum]
        #
        def metageneration
          @gapi.metageneration
        end

        ##
        # A URL that can be used to access the file using the REST API.
        #
        # @return [String]
        #
        def api_url
          @gapi.self_link
        end

        ##
        # A URL that can be used to download the file using the REST API.
        #
        # @return [String]
        #
        def media_url
          @gapi.media_link
        end

        ##
        # Content-Length of the data in bytes.
        #
        # @return [Integer]
        #
        def size
          @gapi.size&.to_i
        end

        ##
        # Creation time of the file.
        #
        # @return [DateTime]
        #
        def created_at
          @gapi.time_created
        end

        ##
        # The creation or modification time of the file.
        # For buckets with versioning enabled, changing an object's
        # metadata does not change this property.
        #
        # @return [DateTime]
        #
        def updated_at
          @gapi.updated
        end

        ##
        # MD5 hash of the data; encoded using base64.
        #
        # @return [String]
        #
        def md5
          @gapi.md5_hash
        end

        ##
        # The CRC32c checksum of the data, as described in
        # [RFC 4960, Appendix B](http://tools.ietf.org/html/rfc4960#appendix-B).
        # Encoded using base64 in big-endian byte order.
        #
        # @return [String]
        #
        def crc32c
          @gapi.crc32c
        end

        ##
        # HTTP 1.1 Entity tag for the file.
        #
        # @return [String]
        #
        def etag
          @gapi.etag
        end

        ##
        # The [Cache-Control](https://tools.ietf.org/html/rfc7234#section-5.2)
        # directive for the file data. If omitted, and the file is accessible
        # to all anonymous users, the default will be `public, max-age=3600`.
        #
        # @return [String]
        #
        def cache_control
          @gapi.cache_control
        end

        ##
        # Updates the
        # [Cache-Control](https://tools.ietf.org/html/rfc7234#section-5.2)
        # directive for the file data. If omitted, and the file is accessible
        # to all anonymous users, the default will be `public, max-age=3600`.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [String] cache_control The Cache-Control directive.
        #
        def cache_control= cache_control
          @gapi.cache_control = cache_control
          update_gapi! :cache_control
        end

        ##
        # The [Content-Disposition](https://tools.ietf.org/html/rfc6266) of the
        # file data.
        #
        # @return [String]
        #
        def content_disposition
          @gapi.content_disposition
        end

        ##
        # Updates the [Content-Disposition](https://tools.ietf.org/html/rfc6266)
        # of the file data.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [String] content_disposition The Content-Disposition of the
        #   file.
        #
        def content_disposition= content_disposition
          @gapi.content_disposition = content_disposition
          update_gapi! :content_disposition
        end

        ##
        # The [Content-Encoding
        # ](https://tools.ietf.org/html/rfc7231#section-3.1.2.2) of the file
        # data.
        #
        # @return [String]
        #
        def content_encoding
          @gapi.content_encoding
        end

        ##
        # Updates the [Content-Encoding
        # ](https://tools.ietf.org/html/rfc7231#section-3.1.2.2) of the file
        # data.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [String] content_encoding The Content-Encoding of the file.
        #
        def content_encoding= content_encoding
          @gapi.content_encoding = content_encoding
          update_gapi! :content_encoding
        end

        ##
        # The [Content-Language](http://tools.ietf.org/html/bcp47) of the file
        # data.
        #
        # @return [String]
        #
        def content_language
          @gapi.content_language
        end

        ##
        # Updates the [Content-Language](http://tools.ietf.org/html/bcp47) of
        # the file data.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [String] content_language The Content-Language of the file.
        #
        def content_language= content_language
          @gapi.content_language = content_language
          update_gapi! :content_language
        end

        ##
        # The [Content-Type](https://tools.ietf.org/html/rfc2616#section-14.17)
        # of the file data.
        #
        # @return [String]
        #
        def content_type
          @gapi.content_type
        end

        ##
        # Updates the
        # [Content-Type](https://tools.ietf.org/html/rfc2616#section-14.17) of
        # the file data.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [String] content_type The Content-Type of the file.
        #
        def content_type= content_type
          @gapi.content_type = content_type
          update_gapi! :content_type
        end

        ##
        # A custom time specified by the user for the file, or `nil`.
        #
        # @return [DateTime, nil]
        #
        def custom_time
          @gapi.custom_time
        end

        ##
        # Updates the custom time specified by the user for the file. Once set,
        # custom_time can't be unset, and it can only be changed to a time in the
        # future. If custom_time must be unset, you must either perform a rewrite
        # operation, or upload the data again and create a new file.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [DateTime] custom_time A custom time specified by the user
        #   for the file.
        #
        def custom_time= custom_time
          @gapi.custom_time = custom_time
          update_gapi! :custom_time
        end

        ##
        # A hash of custom, user-provided web-safe keys and arbitrary string
        # values that will returned with requests for the file as "x-goog-meta-"
        # response headers.
        #
        # @return [Hash(String => String)]
        #
        def metadata
          m = @gapi.metadata
          m = m.to_h if m.respond_to? :to_h
          m.dup.freeze
        end

        ##
        # Updates the hash of custom, user-provided web-safe keys and arbitrary
        # string values that will returned with requests for the file as
        # "x-goog-meta-" response headers.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [Hash(String => String)] metadata The user-provided metadata,
        #   in key/value pairs.
        #
        def metadata= metadata
          @gapi.metadata = metadata
          update_gapi! :metadata
        end

        ##
        # An [RFC 4648](https://tools.ietf.org/html/rfc4648#section-4)
        # Base64-encoded string of the SHA256 hash of the [customer-supplied
        # encryption
        # key](https://cloud.google.com/storage/docs/encryption#customer-supplied).
        # You can use this SHA256 hash to uniquely identify the AES-256
        # encryption key required to decrypt this file.
        #
        # @return [String, nil] The encoded SHA256 hash, or `nil` if there is
        #   no customer-supplied encryption key for this file.
        #
        def encryption_key_sha256
          return nil unless @gapi.customer_encryption
          Base64.decode64 @gapi.customer_encryption.key_sha256
        end

        ##
        # The Cloud KMS encryption key that was used to protect the file, or
        #   `nil` if none has been configured.
        #
        # @see https://cloud.google.com/kms/docs/ Cloud Key Management Service
        #   Documentation
        #
        # @return [String, nil] A Cloud KMS encryption key, or `nil` if none has
        #   been configured.
        #
        def kms_key
          @gapi.kms_key_name
        end

        ##
        # The file's storage class. This defines how the file is stored and
        # determines the SLA and the cost of storage. For more information, see
        # [Storage
        # Classes](https://cloud.google.com/storage/docs/storage-classes) and
        # [Per-Object Storage
        # Class](https://cloud.google.com/storage/docs/per-object-storage-class).
        #
        # @return [String]
        #
        def storage_class
          @gapi.storage_class
        end

        ##
        # Rewrites the file with a new storage class, which determines the SLA
        # and the cost of storage. Accepted values include:
        #
        # * `:standard`
        # * `:nearline`
        # * `:coldline`
        # * `:archive`
        #
        # as well as the equivalent strings returned by {File#storage_class} or
        # {Bucket#storage_class}. For more information, see [Storage
        # Classes](https://cloud.google.com/storage/docs/storage-classes) and
        # [Per-Object Storage
        # Class](https://cloud.google.com/storage/docs/per-object-storage-class).
        # The  default value is the default storage class for the bucket. See
        # {Bucket#storage_class}.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @param [Symbol, String] storage_class Storage class of the file.
        #
        def storage_class= storage_class
          @gapi.storage_class = storage_class_for storage_class
          update_gapi! :storage_class
        end

        ##
        # Whether there is a temporary hold on the file. A temporary hold will
        # be enforced on the file as long as this property is `true`, even if
        # the bucket-level retention policy would normally allow deletion. When
        # the temporary hold is removed, the normal bucket-level policy rules
        # once again apply. The default value is `false`.
        #
        # @return [Boolean] Returns `true` if there is a temporary hold on the
        #   file, otherwise `false`.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.temporary_hold? #=> false
        #   file.set_temporary_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #
        def temporary_hold?
          !@gapi.temporary_hold.nil? && @gapi.temporary_hold
        end

        ##
        # Sets the temporary hold property of the file to `true`. This property
        # is used to enforce a temporary hold on a file. While it is set to
        # `true`, the file is protected against deletion and overwrites. Once
        # removed, the file's `retention_expires_at` date is not changed. The
        # default value is `false`.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # See {#retention_expires_at}.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.temporary_hold? #=> false
        #   file.set_temporary_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #
        def set_temporary_hold!
          @gapi.temporary_hold = true
          update_gapi! :temporary_hold
        end

        ##
        # Sets the temporary hold property of the file to `false`. This property
        # is used to enforce a temporary hold on a file. While it is set to
        # `true`, the file is protected against deletion and overwrites. Once
        # removed, the file's `retention_expires_at` date is not changed. The
        # default value is `false`.
        #
        # See {#retention_expires_at}.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.temporary_hold? #=> false
        #   file.set_temporary_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #
        #   file.release_temporary_hold!
        #   file.delete
        #
        def release_temporary_hold!
          @gapi.temporary_hold = false
          update_gapi! :temporary_hold
        end

        ##
        # Whether there is an event-based hold on the file. An event-based
        # hold will be enforced on the file as long as this property is `true`,
        # even if the bucket-level retention policy would normally allow
        # deletion. Removing the event-based hold extends the retention duration
        # of the file to the current date plus the bucket-level policy duration.
        # Removing the event-based hold represents that a retention-related
        # event has occurred, and thus the retention clock ticks from the moment
        # of the event as opposed to the creation date of the object. The
        # default value is configured at the bucket level (which defaults to
        # `false`), and is assigned to newly-created objects.
        #
        # See {#set_event_based_hold!}, {#release_event_based_hold!},
        # {Bucket#default_event_based_hold?} and
        # {Bucket#default_event_based_hold=}.
        #
        # If a bucket's retention policy duration is modified after the
        # event-based hold flag is unset, the updated retention duration applies
        # retroactively to objects that previously had event-based holds.  For
        # example:
        #
        # * If the bucket's [unlocked] retention policy is removed, objects with
        #   event-based holds may be deleted immediately after the hold is
        #   removed (the duration of a nonexistent policy for the purpose of
        #   event-based holds is considered to be zero).
        # * If the bucket's [unlocked] policy is reduced, objects with
        #   previously released event-based holds will be have their retention
        #   expiration dates reduced accordingly.
        # * If the bucket's policy is extended, objects with previously released
        #   event-based holds will have their retention expiration dates
        #   extended accordingly.  However, note that objects with event-based
        #   holds released prior to the effective date of the new policy may
        #   have already been deleted by the user.
        #
        # @return [Boolean] Returns `true` if there is an event-based hold on
        #   the file, otherwise `false`.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   bucket.retention_period = 2592000 # 30 days in seconds
        #
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.event_based_hold? #=> false
        #   file.set_event_based_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #   file.release_event_based_hold!
        #
        #   # The end of the retention period is calculated from the time that
        #   # the event-based hold was released.
        #   file.retention_expires_at
        #
        def event_based_hold?
          !@gapi.event_based_hold.nil? && @gapi.event_based_hold
        end

        ##
        # Sets the event-based hold property of the file to `true`. This
        # property enforces an event-based hold on the file as long as this
        # property is `true`, even if the bucket-level retention policy would
        # normally allow deletion. The default value is configured at the
        # bucket level (which defaults to `false`), and is assigned to
        # newly-created objects.
        #
        # See {#event_based_hold?}, {#release_event_based_hold!},
        # {Bucket#default_event_based_hold?} and
        # {Bucket#default_event_based_hold=}.
        #
        # If a bucket's retention policy duration is modified after the
        # event-based hold is removed, the updated retention duration applies
        # retroactively to objects that previously had event-based holds.  For
        # example:
        #
        # * If the bucket's [unlocked] retention policy is removed, objects with
        #   event-based holds may be deleted immediately after the hold is
        #   removed (the duration of a nonexistent policy for the purpose of
        #   event-based holds is considered to be zero).
        # * If the bucket's [unlocked] policy is reduced, objects with
        #   previously released event-based holds will be have their retention
        #   expiration dates reduced accordingly.
        # * If the bucket's policy is extended, objects with previously released
        #   event-based holds will have their retention expiration dates
        #   extended accordingly.  However, note that objects with event-based
        #   holds released prior to the effective date of the new policy may
        #   have already been deleted by the user.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   bucket.retention_period = 2592000 # 30 days in seconds
        #
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.event_based_hold? #=> false
        #   file.set_event_based_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #   file.release_event_based_hold!
        #
        #   # The end of the retention period is calculated from the time that
        #   # the event-based hold was released.
        #   file.retention_expires_at
        #
        def set_event_based_hold!
          @gapi.event_based_hold = true
          update_gapi! :event_based_hold
        end

        ##
        # Sets the event-based hold property of the file to `false`. Removing
        # the event-based hold extends the retention duration of the file to the
        # current date plus the bucket-level policy duration. Removing the
        # event-based hold represents that a retention-related event has
        # occurred, and thus the retention clock ticks from the moment of the
        # event as opposed to the creation date of the object. The default value
        # is configured at the bucket level (which defaults to `false`), and is
        # assigned to newly-created objects.
        #
        # See {#event_based_hold?}, {#set_event_based_hold!},
        # {Bucket#default_event_based_hold?} and
        # {Bucket#default_event_based_hold=}.
        #
        # To pass generation and/or metageneration preconditions, call this
        # method within a block passed to {#update}.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   bucket.retention_period = 2592000 # 30 days in seconds
        #
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.event_based_hold? #=> false
        #   file.set_event_based_hold!
        #   file.delete # raises Google::Cloud::PermissionDeniedError
        #   file.release_event_based_hold!
        #
        #   # The end of the retention period is calculated from the time that
        #   # the event-based hold was released.
        #   file.retention_expires_at
        #
        def release_event_based_hold!
          @gapi.event_based_hold = false
          update_gapi! :event_based_hold
        end

        ##
        # The retention expiration time of the file. This field is indirectly
        # mutable when the retention policy applicable to the object changes.
        # The date represents the earliest time that the object could be
        # deleted, assuming no temporary hold is set. (See {#temporary_hold?}.)
        # It is provided when both of the following are true:
        #
        # * There is a retention policy on the bucket.
        # * The eventBasedHold flag is unset on the object.
        #
        # Note that it can be provided even when {#temporary_hold?} is `true`
        # (so that the user can reason about policy without having to first
        # unset the temporary hold).
        #
        # @return [DateTime, nil] A DateTime representing the earliest time at
        #   which the object can be deleted, or `nil` if there are no
        #   restrictions on deleting the object.
        #
        def retention_expires_at
          @gapi.retention_expiration_time
        end

        ##
        # This soft delete time is the time when the object became
        # soft-deleted.
        #
        # @return [DateTime, nil] A DateTime representing the time at
        #   which the object became soft-deleted, or `nil` if the file was
        #   not deleted.
        #
        def soft_delete_time
          @gapi.soft_delete_time
        end

        ##
        # This hard delete time is The time when the file will be permanently
        # deleted.
        #
        # @return [DateTime, nil] A DateTime representing the time at
        #   which the file will be permanently deleted, or `nil` if the file is
        #   not soft deleted.
        #
        def hard_delete_time
          @gapi.hard_delete_time
        end

        ##
        # Retrieves a list of versioned files for the current object.
        #
        # Useful for listing archived versions of the file, restoring the live
        # version of the file to an older version, or deleting an archived
        # version. You can turn versioning on or off for a bucket at any time
        # with {Bucket#versioning=}. Turning versioning off leaves existing file
        # versions in place and causes the bucket to stop accumulating new
        # archived object versions. (See {Bucket#versioning?} and
        # {File#generation})
        #
        # @see https://cloud.google.com/storage/docs/object-versioning Object
        #   Versioning
        #
        # @return [Array<Google::Cloud::Storage::File>] (See
        #   {Google::Cloud::Storage::File::List})
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.generation #=> 1234567890
        #   file.generations.each do |versioned_file|
        #     versioned_file.generation
        #   end
        #
        def generations
          ensure_service!
          gapi = service.list_files bucket, prefix: name,
                                            versions: true,
                                            user_project: user_project
          File::List.from_gapi gapi, service, bucket, name, nil, nil, true,
                               user_project: user_project
        end

        ##
        # Updates the file with changes made in the given block in a single
        # PATCH request. The following attributes may be set: {#cache_control=},
        # {#content_disposition=}, {#content_encoding=}, {#content_language=},
        # {#content_type=}, {#custom_time=} and {#metadata=}. The {#metadata} hash
        # accessible in the block is completely mutable and will be included in the
        # request.
        #
        # @param [Integer] generation Select a specific revision of the file to
        #   update. The default is the latest version.
        # @param [Integer] if_generation_match Makes the operation conditional
        #   on whether the file's current generation matches the given value.
        #   Setting to 0 makes the operation succeed only if there are no live
        #   versions of the file.
        # @param [Integer] if_generation_not_match Makes the operation conditional
        #   on whether the file's current generation does not match the given
        #   value. If no live file exists, the precondition fails. Setting to 0
        #   makes the operation succeed only if there is a live version of the file.
        # @param [Integer] if_metageneration_match Makes the operation conditional
        #   on whether the file's current metageneration matches the given value.
        # @param [Integer] if_metageneration_not_match Makes the operation
        #   conditional on whether the file's current metageneration does not
        #   match the given value.
        # @param [Boolean] override_unlocked_retention
        #   Must be true to remove the retention configuration, reduce its unlocked
        #   retention period, or change its mode from unlocked to locked.
        #
        # @yield [file] a block yielding a delegate object for updating the file
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.update do |f|
        #     f.cache_control = "private, max-age=0, no-cache"
        #     f.content_disposition = "inline; filename=filename.ext"
        #     f.content_encoding = "deflate"
        #     f.content_language = "de"
        #     f.content_type = "application/json"
        #     f.custom_time = DateTime.new 2025, 12, 31
        #     f.metadata["player"] = "Bob"
        #     f.metadata["score"] = "10"
        #   end
        #
        # @example With a `if_generation_match` precondition:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   file.update if_generation_match: 1602263125261858 do |f|
        #     f.cache_control = "private, max-age=0, no-cache"
        #   end
        #
        def update generation: nil,
                   if_generation_match: nil,
                   if_generation_not_match: nil,
                   if_metageneration_match: nil,
                   if_metageneration_not_match: nil,
                   override_unlocked_retention: nil
          updater = Updater.new gapi
          yield updater
          updater.check_for_changed_metadata!
          return if updater.updates.empty?
          update_gapi! updater.updates,
                       generation: generation,
                       if_generation_match: if_generation_match,
                       if_generation_not_match: if_generation_not_match,
                       if_metageneration_match: if_metageneration_match,
                       if_metageneration_not_match: if_metageneration_not_match,
                       override_unlocked_retention: override_unlocked_retention
        end

        ##
        # Downloads the file's contents to a local file or an File-like object.
        #
        # By default, the download is verified by calculating the MD5 digest.
        #
        # If a [customer-supplied encryption
        # key](https://cloud.google.com/storage/docs/encryption#customer-supplied)
        # was used with {Bucket#create_file}, the `encryption_key` option must
        # be provided.
        #
        # @param [String, ::File] path The path on the local file system to
        #   write the data to. The path provided must be writable. Can also be
        #   an File object, or File-like object such as StringIO. If an file
        #   object, the object will be written to, not the filesystem. If
        #   omitted, a new StringIO instance will be written to and returned.
        #   Optional.
        # @param [Symbol] verify The verification algorithm used to ensure the
        #   downloaded file contents are correct. Default is `:md5`.
        #
        #   Acceptable values are:
        #
        #   * `md5` - Verify file content match using the MD5 hash.
        #   * `crc32c` - Verify file content match using the CRC32c hash.
        #   * `all` - Perform all available file content verification.
        #   * `none` - Don't perform file content verification.
        #
        # @param [String] encryption_key Optional. The customer-supplied,
        #   AES-256 encryption key used to encrypt the file, if one was provided
        #   to {Bucket#create_file}.
        #
        # @param [Range, String] range Optional. The byte range of the file's
        #   contents to download or a string header value. Provide this to
        #   perform a partial download. When a range is provided, no
        #   verification is performed regardless of the `verify` parameter's
        #   value.
        #
        # @param [Boolean] skip_decompress Optional. If `true`, the data for a
        #   Storage object returning a `Content-Encoding: gzip` response header
        #   will *not* be automatically decompressed by this client library. The
        #   default is `nil`. Note that all requests by this client library send
        #   the `Accept-Encoding: gzip` header, so decompressive transcoding is
        #   not performed in the Storage service. (See [Transcoding of
        #   gzip-compressed files](https://cloud.google.com/storage/docs/transcoding))
        #
        # @return [::File, StringIO] Returns a file object representing the file
        #   data. This will ordinarily be a `::File` object referencing the
        #   local file system. However, if the argument to `path` is `nil`, a
        #   StringIO instance will be returned. If the argument to `path` is an
        #   File-like object, then that object will be returned.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.download "path/to/downloaded/file.ext"
        #
        # @example Use the CRC32c digest by passing :crc32c.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.download "path/to/downloaded/file.ext", verify: :crc32c
        #
        # @example Use the MD5 and CRC32c digests by passing :all.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.download "path/to/downloaded/file.ext", verify: :all
        #
        # @example Disable the download verification by passing :none.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.download "path/to/downloaded/file.ext", verify: :none
        #
        # @example Download to an in-memory StringIO object.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   downloaded = file.download
        #   downloaded.rewind
        #   downloaded.read #=> "Hello world!"
        #
        # @example Download a public file with an unauthenticated client.
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.anonymous
        #
        #   bucket = storage.bucket "public-bucket", skip_lookup: true
        #   file = bucket.file "path/to/public-file.ext", skip_lookup: true
        #
        #   downloaded = file.download
        #   downloaded.rewind
        #   downloaded.read #=> "Hello world!"
        #
        # @example Upload and download gzip-encoded file data.
        #   require "zlib"
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   gz = StringIO.new ""
        #   z = Zlib::GzipWriter.new gz
        #   z.write "Hello world!"
        #   z.close
        #   data = StringIO.new gz.string
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   bucket.create_file data, "path/to/gzipped.txt",
        #                      content_encoding: "gzip"
        #
        #   file = bucket.file "path/to/gzipped.txt"
        #
        #   # The downloaded data is decompressed by default.
        #   file.download "path/to/downloaded/hello.txt"
        #
        #   # The downloaded data remains compressed with skip_decompress.
        #   file.download "path/to/downloaded/gzipped.txt",
        #                 skip_decompress: true
        #
        # @example Partially download.
        #
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "path/to/my-file.ext"
        #
        #   downloaded = file.download range: 6..10
        #   downloaded.rewind
        #   downloaded.read #=> "world"
        #
        def download path = nil, verify: :md5, encryption_key: nil, range: nil,
                     skip_decompress: nil
          ensure_service!
          if path.nil?
            path = StringIO.new
            path.set_encoding "ASCII-8BIT"
          end
          file, resp =
            service.download_file bucket, name, path,
                                  generation: generation, key: encryption_key,
                                  range: range, user_project: user_project
          # FIX: downloading with encryption key will return nil
          file ||= ::File.new path
          verify = :none if range
          verify_file! file, verify
          if !skip_decompress &&
             Array(resp.header["Content-Encoding"]).include?("gzip")
            file = gzip_decompress file
          end
          file
        end

        ##
        # Copies the file to a new location. Metadata excluding ACL from the source
        # object will be copied to the destination object unless a block is provided.
        #
        # If an optional block for updating is provided, only the updates made in
        # this block will appear in the destination object, and other metadata
        # fields in the destination object will not be copied. To copy the other
        # source file metadata fields while updating destination fields in a
        # block, use the `force_copy_metadata: true` flag, and the client library
        # will copy metadata from source metadata into the copy request.
        #
        # If a [customer-supplied encryption
        # key](https://cloud.google.com/storage/docs/encryption#customer-supplied)
        # was used with {Bucket#create_file}, the `encryption_key` option must
        # be provided.
        #
        # @param [String] dest_bucket_or_path Either the bucket to copy the file
        #   to, or the path to copy the file to in the current bucket.
        # @param [String] dest_path If a bucket was provided in the first
        #   parameter, this contains the path to copy the file to in the given
        #   bucket.
        # @param [String] acl A predefined set of access controls to apply to
        #   new file.
        #
        #   Acceptable values are:
        #
        #   * `auth`, `auth_read`, `authenticated`, `authenticated_read`,
        #     `authenticatedRead` - File owner gets OWNER access, and
        #     allAuthenticatedUsers get READER access.
        #   * `owner_full`, `bucketOwnerFullControl` - File owner gets OWNER
        #     access, and project team owners get OWNER access.
        #   * `owner_read`, `bucketOwnerRead` - File owner gets OWNER access,
        #     and project team owners get READER access.
        #   * `private` - File owner gets OWNER access.
        #   * `project_private`, `projectPrivate` - File owner gets OWNER
        #     access, and project team members get access according to their
        #     roles.
        #   * `public`, `public_read`, `publicRead` - File owner gets OWNER
        #     access, and allUsers get READER access.
        # @param [Integer] generation Select a specific revision of the file to
        #   copy. The default is the latest version.
        # @param [String] encryption_key Optional. The customer-supplied,
        #   AES-256 encryption key used to encrypt the file, if one was provided
        #   to {Bucket#create_file}.
        # @param [Boolean] force_copy_metadata Optional. If `true` and if updates
        #   are made in a block, the following fields will be copied from the
        #   source file to the destination file (except when changed by updates):
        #
        #   * `cache_control`
        #   * `content_disposition`
        #   * `content_encoding`
        #   * `content_language`
        #   * `content_type`
        #   * `metadata`
        #
        #   If `nil` or `false`, only the updates made in the yielded block will
        #   be applied to the destination object. The default is `nil`.
        # @yield [file] a block yielding a delegate object for updating
        #
        # @return [Google::Cloud::Storage::File]
        #
        # @example The file can be copied to a new path in the current bucket:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.copy "path/to/destination/file.ext"
        #
        # @example The file can also be copied to a different bucket:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.copy "new-destination-bucket",
        #             "path/to/destination/file.ext"
        #
        # @example The file can also be copied by specifying a generation:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.copy "copy/of/previous/generation/file.ext",
        #             generation: 123456
        #
        # @example The file can be modified during copying:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.copy "new-destination-bucket",
        #             "path/to/destination/file.ext" do |f|
        #     f.metadata["copied_from"] = "#{file.bucket}/#{file.name}"
        #   end
        #
        def copy dest_bucket_or_path, dest_path = nil, acl: nil, generation: nil, encryption_key: nil,
                 force_copy_metadata: nil
          rewrite dest_bucket_or_path, dest_path,
                  acl: acl, generation: generation,
                  encryption_key: encryption_key,
                  new_encryption_key: encryption_key,
                  force_copy_metadata: force_copy_metadata do |updater|
            yield updater if block_given?
          end
        end

        ##
        # [Rewrites](https://cloud.google.com/storage/docs/json_api/v1/objects/rewrite)
        # the file to a new location. Or the same location can be provided to
        # rewrite the file in place. Metadata from the source object will
        # be copied to the destination object unless a block is provided.
        #
        # If an optional block for updating is provided, only the updates made in
        # this block will appear in the destination object, and other metadata
        # fields in the destination object will not be copied. To copy the other
        # source file metadata fields while updating destination fields in a
        # block, use the `force_copy_metadata: true` flag, and the client library
        # will copy metadata from source metadata into the copy request.
        #
        # If a [customer-supplied encryption
        # key](https://cloud.google.com/storage/docs/encryption#customer-supplied)
        # was used with {Bucket#create_file}, the `encryption_key` option must
        # be provided. Unlike {#copy}, separate encryption keys are used to read
        # (encryption_key) and to write (new_encryption_key) file contents.
        #
        # @param [String] dest_bucket_or_path Either the bucket to rewrite the
        #   file to, or the path to rewrite the file to in the current bucket.
        # @param [String] dest_path If a bucket was provided in the first
        #   parameter, this contains the path to rewrite the file to in the
        #   given bucket.
        # @param [String] acl A predefined set of access controls to apply to
        #   new file.
        #
        #   Acceptable values are:
        #
        #   * `auth`, `auth_read`, `authenticated`, `authenticated_read`,
        #     `authenticatedRead` - File owner gets OWNER access, and
        #     allAuthenticatedUsers get READER access.
        #   * `owner_full`, `bucketOwnerFullControl` - File owner gets OWNER
        #     access, and project team owners get OWNER access.
        #   * `owner_read`, `bucketOwnerRead` - File owner gets OWNER access,
        #     and project team owners get READER access.
        #   * `private` - File owner gets OWNER access.
        #   * `project_private`, `projectPrivate` - File owner gets OWNER
        #     access, and project team members get access according to their
        #     roles.
        #   * `public`, `public_read`, `publicRead` - File owner gets OWNER
        #     access, and allUsers get READER access.
        # @param [Integer] generation Select a specific revision of the file to
        #   rewrite. The default is the latest version.
        # @param [Integer] if_generation_match Makes the operation conditional
        #   on whether the destination file's current generation matches the given value.
        #   Setting to 0 makes the operation succeed only if there are no live
        #   versions of the file.
        # @param [Integer] if_generation_not_match Makes the operation conditional
        #   on whether the destination file's current generation does not match the given
        #   value. If no live file exists, the precondition fails. Setting to 0
        #   makes the operation succeed only if there is a live version of the file.
        # @param [Integer] if_metageneration_match Makes the operation conditional
        #   on whether the destination file's current metageneration matches the given value.
        # @param [Integer] if_metageneration_not_match Makes the operation
        #   conditional on whether the destination file's current metageneration does not
        #   match the given value.
        # @param [Integer] if_source_generation_match Makes the operation conditional on
        #   whether the source object's current generation matches the given value.
        # @param [Integer] if_source_generation_not_match Makes the operation conditional
        #   on whether the source object's current generation does not match the given value.
        # @param [Integer] if_source_metageneration_match Makes the operation conditional
        #   on whether the source object's current metageneration matches the given value.
        # @param [Integer] if_source_metageneration_not_match Makes the operation conditional
        #   on whether the source object's current metageneration does not match the given value.
        # @param [String] encryption_key Optional. The customer-supplied,
        #   AES-256 encryption key used to decrypt the file, if the existing
        #   file is encrypted.
        # @param [String, nil] new_encryption_key Optional. The new
        #   customer-supplied, AES-256 encryption key with which to encrypt the
        #   file. If not provided, the rewritten file will be encrypted using
        #   the default server-side encryption, or the `new_kms_key` if one is
        #   provided. Do not provide if `new_kms_key` is used.
        # @param [String] new_kms_key Optional. Resource name of the Cloud KMS
        #   key, of the form
        #   `projects/my-prj/locations/kr-loc/keyRings/my-kr/cryptoKeys/my-key`,
        #   that will be used to encrypt the file. The KMS key ring must use
        #   the same location as the bucket.The Service Account associated with
        #   your project requires access to this encryption key. Do not provide
        #   if `new_encryption_key` is used.
        # @param [Boolean] force_copy_metadata Optional. If `true` and if updates
        #   are made in a block, the following fields will be copied from the
        #   source file to the destination file (except when changed by updates):
        #
        #   * `cache_control`
        #   * `content_disposition`
        #   * `content_encoding`
        #   * `content_language`
        #   * `content_type`
        #   * `metadata`
        #
        #   If `nil` or `false`, only the updates made in the yielded block will
        #   be applied to the destination object. The default is `nil`.
        # @yield [file] a block yielding a delegate object for updating
        #
        # @return [Google::Cloud::Storage::File]
        #
        # @example The file can be rewritten to a new path in the bucket:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.rewrite "path/to/destination/file.ext"
        #
        # @example The file can also be rewritten to a different bucket:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.rewrite "new-destination-bucket",
        #                "path/to/destination/file.ext"
        #
        # @example The file can also be rewritten by specifying a generation:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.rewrite "copy/of/previous/generation/file.ext",
        #                generation: 123456
        #
        # @example The file can be modified during rewriting:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.rewrite "new-destination-bucket",
        #                "path/to/destination/file.ext" do |f|
        #     f.metadata["rewritten_from"] = "#{file.bucket}/#{file.name}"
        #   end
        #
        # @example Rewriting with a customer-supplied encryption key:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   # Old key was stored securely for later use.
        #   old_key = "y\x03\"\x0E\xB6\xD3\x9B\x0E\xAB*\x19\xFAv\xDEY\xBEI..."
        #
        #   # Key generation shown for example purposes only. Write your own.
        #   cipher = OpenSSL::Cipher.new "aes-256-cfb"
        #   cipher.encrypt
        #   new_key = cipher.random_key
        #
        #   file = bucket.file "path/to/my-file.ext", encryption_key: old_key
        #   file.rewrite "new-destination-bucket",
        #                "path/to/destination/file.ext",
        #                encryption_key: old_key,
        #                new_encryption_key: new_key do |f|
        #     f.metadata["rewritten_from"] = "#{file.bucket}/#{file.name}"
        #   end
        #
        # @example Rewriting with a customer-managed Cloud KMS encryption key:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   # KMS key ring must use the same location as the bucket.
        #   kms_key_name = "projects/a/locations/b/keyRings/c/cryptoKeys/d"
        #
        #   # Old customer-supplied key was stored securely for later use.
        #   old_key = "y\x03\"\x0E\xB6\xD3\x9B\x0E\xAB*\x19\xFAv\xDEY\xBEI..."
        #
        #   file = bucket.file "path/to/my-file.ext", encryption_key: old_key
        #   file.rewrite "new-destination-bucket",
        #                "path/to/destination/file.ext",
        #                encryption_key: old_key,
        #                new_kms_key: kms_key_name do |f|
        #     f.metadata["rewritten_from"] = "#{file.bucket}/#{file.name}"
        #   end
        #
        def rewrite dest_bucket_or_path,
                    dest_path = nil,
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
                    encryption_key: nil,
                    new_encryption_key: nil,
                    new_kms_key: nil,
                    force_copy_metadata: nil
          ensure_service!
          dest_bucket, dest_path = fix_rewrite_args dest_bucket_or_path, dest_path

          update_gapi = nil
          if block_given?
            updater = Updater.new gapi.dup
            yield updater
            updater.check_for_changed_metadata!
            if updater.updates.any?
              attributes = force_copy_metadata ? (Updater::COPY_ATTRS + updater.updates).uniq : updater.updates
              update_gapi = self.class.gapi_from_attrs updater.gapi, attributes
            end
          end

          new_gapi = rewrite_gapi bucket,
                                  name,
                                  update_gapi,
                                  new_bucket: dest_bucket,
                                  new_name: dest_path,
                                  acl: acl,
                                  generation: generation,
                                  if_generation_match: if_generation_match,
                                  if_generation_not_match: if_generation_not_match,
                                  if_metageneration_match: if_metageneration_match,
                                  if_metageneration_not_match: if_metageneration_not_match,
                                  if_source_generation_match: if_source_generation_match,
                                  if_source_generation_not_match: if_source_generation_not_match,
                                  if_source_metageneration_match: if_source_metageneration_match,
                                  if_source_metageneration_not_match: if_source_metageneration_not_match,
                                  encryption_key: encryption_key,
                                  new_encryption_key: new_encryption_key,
                                  new_kms_key: new_kms_key,
                                  user_project: user_project

          File.from_gapi new_gapi, service, user_project: user_project
        end

        ##
        # [Rewrites](https://cloud.google.com/storage/docs/json_api/v1/objects/rewrite)
        # the file to the same {#bucket} and {#name} with a new
        # [customer-supplied encryption
        # key](https://cloud.google.com/storage/docs/encryption#customer-supplied).
        #
        # If a new key is provided to this method, the new key must be used to
        # subsequently download or copy the file. You must securely manage your
        # keys and ensure that they are not lost. Also, please note that file
        # metadata is not encrypted, with the exception of the CRC32C checksum
        # and MD5 hash. The names of files and buckets are also not encrypted,
        # and you can read or update the metadata of an encrypted file without
        # providing the encryption key.
        #
        # @see https://cloud.google.com/storage/docs/encryption
        #
        # @param [String, nil] encryption_key Optional. The last
        #   customer-supplied, AES-256 encryption key used to encrypt the file,
        #   if one was used.
        # @param [String, nil] new_encryption_key Optional. The new
        #   customer-supplied, AES-256 encryption key with which to encrypt the
        #   file. If not provided, the rewritten file will be encrypted using
        #   the default server-side encryption, or the `new_kms_key` if one is
        #   provided. Do not provide if `new_kms_key` is used.
        # @param [String] new_kms_key Optional. Resource name of the Cloud KMS
        #   key, of the form
        #   `projects/my-prj/locations/kr-loc/keyRings/my-kr/cryptoKeys/my-key`,
        #   that will be used to encrypt the file. The KMS key ring must use
        #   the same location as the bucket.The Service Account associated with
        #   your project requires access to this encryption key. Do not provide
        #   if `new_encryption_key` is used.
        #
        # @return [Google::Cloud::Storage::File]
        #
        # @example Rotating to a new customer-supplied encryption key:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   # Old key was stored securely for later use.
        #   old_key = "y\x03\"\x0E\xB6\xD3\x9B\x0E\xAB*\x19\xFAv\xDEY\xBEI..."
        #
        #   file = bucket.file "path/to/my-file.ext", encryption_key: old_key
        #
        #   # Key generation shown for example purposes only. Write your own.
        #   cipher = OpenSSL::Cipher.new "aes-256-cfb"
        #   cipher.encrypt
        #   new_key = cipher.random_key
        #
        #   file.rotate encryption_key: old_key, new_encryption_key: new_key
        #
        # @example Rotating to a customer-managed Cloud KMS encryption key:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #
        #   # KMS key ring must use the same location as the bucket.
        #   kms_key_name = "projects/a/locations/b/keyRings/c/cryptoKeys/d"
        #
        #   # Old key was stored securely for later use.
        #   old_key = "y\x03\"\x0E\xB6\xD3\x9B\x0E\xAB*\x19\xFAv\xDEY\xBEI..."
        #
        #   file = bucket.file "path/to/my-file.ext", encryption_key: old_key
        #
        #   file.rotate encryption_key: old_key, new_kms_key: kms_key_name
        #
        def rotate encryption_key: nil, new_encryption_key: nil,
                   new_kms_key: nil
          rewrite bucket, name, encryption_key: encryption_key,
                                new_encryption_key: new_encryption_key,
                                new_kms_key: new_kms_key
        end

        ##
        # Permanently deletes the file.
        #
        # Raises PermissionDeniedError if the object is subject to an active
        # retention policy or hold. (See {#retention_expires_at},
        # {Bucket#retention_period}, {#temporary_hold?} and
        # {#event_based_hold?}.)
        #
        # @param [Boolean, Integer] generation Specify a version of the file to
        #   delete. When `true`, it will delete the version returned by
        #   {#generation}. The default behavior is to delete the latest version
        #   of the file (regardless of the version to which the file is set,
        #   which is the version returned by {#generation}.)
        # @param [Integer] if_generation_match Makes the operation conditional
        #   on whether the file's current generation matches the given value.
        #   Setting to 0 makes the operation succeed only if there are no live
        #   versions of the file.
        # @param [Integer] if_generation_not_match Makes the operation conditional
        #   on whether the file's current generation does not match the given
        #   value. If no live file exists, the precondition fails. Setting to 0
        #   makes the operation succeed only if there is a live version of the file.
        # @param [Integer] if_metageneration_match Makes the operation conditional
        #   on whether the file's current metageneration matches the given value.
        # @param [Integer] if_metageneration_not_match Makes the operation
        #   conditional on whether the file's current metageneration does not
        #   match the given value.
        #
        # @return [Boolean] Returns `true` if the file was deleted.
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.delete
        #
        # @example The file's generation can used by passing `true`:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.delete generation: true
        #
        # @example A generation can also be specified:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.delete generation: 123456
        #
        def delete generation: nil,
                   if_generation_match: nil,
                   if_generation_not_match: nil,
                   if_metageneration_match: nil,
                   if_metageneration_not_match: nil
          generation = self.generation if generation == true
          ensure_service!
          service.delete_file bucket,
                              name,
                              generation: generation,
                              if_generation_match: if_generation_match,
                              if_generation_not_match: if_generation_not_match,
                              if_metageneration_match: if_metageneration_match,
                              if_metageneration_not_match: if_metageneration_not_match,
                              user_project: user_project
          true
        end

        # Mode of object level retention configuration.
        # Valid values are 'Locked' or 'Unlocked'
        #
        # @return [String]
        def retention_mode
          @gapi.retention&.mode
        end

        # The earliest time in RFC 3339 UTC "Zulu" format that the object can
        # be deleted or replaced.
        #
        # @return [DateTime]
        def retention_retain_until_time
          @gapi.retention&.retain_until_time
        end

        # A collection of object level retention parameters.
        # The full list of available options are outlined at the [JSON API docs]
        # (https://cloud.google.com/storage/docs/json_api/v1/objects/insert#request-body).
        #
        # @return [Google::Apis::StorageV1::Object::Retention]
        def retention
          @gapi.retention
        end

        ##
        # Update method to update retention parameter of an object / file
        # It accepts params as a Hash of attributes in the following format:
        #
        #     { mode: 'Locked|Unlocked', retain_until_time: '2023-12-19T03:22:23+00:00' }
        #
        # @param [Hash(String => String)] new_retention_attributes
        #
        # @example Update retention parameters for the File / Object
        #   require "google/cloud/storage"
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   retention_params = { mode: 'Unlocked', retain_until_time: '2023-12-19T03:22:23+00:00'.to_datetime }
        #   file.retention = retention_params
        #
        # @example Update retention parameters for the File / Object with override enabled
        #   require "google/cloud/storage"
        #   storage = Google::Cloud::Storage.new
        #   bucket = storage.bucket "my-bucket"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   retention_params = { mode: 'Unlocked',
        #                        retain_until_time: '2023-12-19T03:22:23+00:00'.to_datetime,
        #                        override_unlocked_retention: true }
        #   file.retention = retention_params
        #
        def retention= new_retention_attributes
          @gapi.retention ||= Google::Apis::StorageV1::Object::Retention.new
          @gapi.retention.mode = new_retention_attributes[:mode]
          @gapi.retention.retain_until_time = new_retention_attributes[:retain_until_time]
          update_gapi! :retention, override_unlocked_retention: new_retention_attributes[:override_unlocked_retention]
        end

        ##
        # Public URL to access the file. If the file is not public, requests to
        # the URL will return an error. (See {File::Acl#public!} and
        # {Bucket::DefaultAcl#public!}) To share a file that is not public see
        # {#signed_url}.
        #
        # @see https://cloud.google.com/storage/docs/access-public-data
        #   Accessing Public Data
        #
        # @param [String] protocol The protocol to use for the URL. Default is
        #   `HTTPS`.
        #
        # @return [String]
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   public_url = file.public_url
        #
        # @example Generate the URL with a protocol other than HTTPS:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   public_url = file.public_url protocol: "http"
        #
        def public_url protocol: :https
          "#{protocol}://storage.googleapis.com/#{bucket}/#{name}"
        end
        alias url public_url

        ##
        # Generates a signed URL for the file. See [Signed
        # URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
        # for more information.
        #
        # Generating a signed URL requires service account credentials, either
        # by connecting with a service account when calling
        # {Google::Cloud.storage}, or by passing in the service account `issuer`
        # and `signing_key` values. Although the private key can be passed as a
        # string for convenience, creating and storing an instance of
        # `OpenSSL::PKey::RSA` is more efficient when making multiple calls to
        # `signed_url`.
        #
        # A {SignedUrlUnavailable} is raised if the service account credentials
        # are missing. Service account credentials are acquired by following the
        # steps in [Service Account Authentication](
        # https://cloud.google.com/iam/docs/service-accounts).
        #
        # @see https://cloud.google.com/storage/docs/access-control/signed-urls
        #   Signed URLs guide
        # @see https://cloud.google.com/storage/docs/access-control/signed-urls#signing-resumable
        #   Using signed URLs with resumable uploads
        #
        # @param [String] method The HTTP verb to be used with the signed URL.
        #   Signed URLs can be used
        #   with `GET`, `HEAD`, `PUT`, and `DELETE` requests. Default is `GET`.
        # @param [Integer] expires The number of seconds until the URL expires.
        #   If the `version` is `:v2`, the default is 300 (5 minutes). If the
        #   `version` is `:v4`, the default is 604800 (7 days).
        # @param [String] content_type When provided, the client (browser) must
        #   send this value in the HTTP header. e.g. `text/plain`. This param is
        #   not used if the `version` is `:v4`.
        # @param [String] content_md5 The MD5 digest value in base64. If you
        #   provide this in the string, the client (usually a browser) must
        #   provide this HTTP header with this same value in its request. This
        #   param is not used if the `version` is `:v4`.
        # @param [Hash] headers Google extension headers (custom HTTP headers
        #   that begin with `x-goog-`) that must be included in requests that
        #   use the signed URL.
        # @param [String] issuer Service Account's Client Email.
        # @param [String] client_email Service Account's Client Email.
        # @param [OpenSSL::PKey::RSA, String, Proc] signing_key Service Account's
        #   Private Key or a Proc that accepts a single String parameter and returns a
        #   RSA SHA256 signature using a valid Google Service Account Private Key.
        # @param [OpenSSL::PKey::RSA, String, Proc] private_key Service Account's
        #   Private Key or a Proc that accepts a single String parameter and returns a
        #   RSA SHA256 signature using a valid Google Service Account Private Key.
        # @param [OpenSSL::PKey::RSA, String, Proc] signer Service Account's
        #   Private Key or a Proc that accepts a single String parameter and returns a
        #   RSA SHA256 signature using a valid Google Service Account Private Key.
        #
        #   When using this method in environments such as GAE Flexible Environment,
        #   GKE, or Cloud Functions where the private key is unavailable, it may be
        #   necessary to provide a Proc (or lambda) via the signer parameter. This
        #   Proc should return a signature created using a RPC call to the
        #   [Service Account Credentials signBlob](https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob)
        #   method as shown in the example below.
        # @param [Hash] query Query string parameters to include in the signed
        #   URL. The given parameters are not verified by the signature.
        #
        #   Parameters such as `response-content-disposition` and
        #   `response-content-type` can alter the behavior of the response when
        #   using the URL, but only when the file resource is missing the
        #   corresponding values. (These values can be permanently set using
        #   {#content_disposition=} and {#content_type=}.)
        # @param [String] scheme The URL scheme. The default value is `HTTPS`.
        # @param [Boolean] virtual_hosted_style Whether to use a virtual hosted-style
        #   hostname, which adds the bucket into the host portion of the URI rather
        #   than the path, e.g. `https://mybucket.storage.googleapis.com/...`.
        #   For V4 signing, this also sets the `host` header in the canonicalized
        #   extension headers to the virtual hosted-style host, unless that header is
        #   supplied via the `headers` param. The default value of `false` uses the
        #   form of `https://storage.googleapis.com/mybucket`.
        # @param [String] bucket_bound_hostname Use a bucket-bound hostname, which
        #   replaces the `storage.googleapis.com` host with the name of a `CNAME`
        #   bucket, e.g. a bucket named `gcs-subdomain.my.domain.tld`, or a Google
        #   Cloud Load Balancer which routes to a bucket you own, e.g.
        #   `my-load-balancer-domain.tld`.
        # @param [Symbol, String] version The version of the signed credential
        #   to create. Must be one of `:v2` or `:v4`. The default value is
        #   `:v2`.
        #
        # @return [String] The signed URL.
        #
        # @raise [SignedUrlUnavailable] If the service account credentials
        #   are missing. Service account credentials are acquired by following the
        #   steps in [Service Account Authentication](
        #   https://cloud.google.com/iam/docs/service-accounts).
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   shared_url = file.signed_url
        #
        # @example Using the `expires` and `version` options:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   shared_url = file.signed_url expires: 300, # 5 minutes from now
        #                                version: :v4
        #
        # @example Using the `issuer` and `signing_key` options:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   key = OpenSSL::PKey::RSA.new "-----BEGIN PRIVATE KEY-----\n..."
        #   shared_url = file.signed_url issuer: "service-account@gcloud.com",
        #                                signing_key: key
        #
        # @example Using the `headers` option:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #   shared_url = file.signed_url method: "GET",
        #                                headers: {
        #                                  "x-goog-acl" => "public-read",
        #                                  "x-goog-meta-foo" => "bar,baz"
        #                                }
        #
        # @example Generating a signed URL for resumable upload:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png", skip_lookup: true
        #   url = file.signed_url method: "POST",
        #                         content_type: "image/png",
        #                         headers: {
        #                           "x-goog-resumable" => "start"
        #                         }
        #   # Send the `x-goog-resumable:start` header and the content type
        #   # with the resumable upload POST request.
        #
        # @example Using Cloud IAMCredentials signBlob to create the signature:
        #   require "google/cloud/storage"
        #   require "google/apis/iamcredentials_v1"
        #   require "googleauth"
        #
        #   # Issuer is the service account email that the Signed URL will be signed with
        #   # and any permission granted in the Signed URL must be granted to the
        #   # Google Service Account.
        #   issuer = "service-account@project-id.iam.gserviceaccount.com"
        #
        #   # Create a lambda that accepts the string_to_sign
        #   signer = lambda do |string_to_sign|
        #     IAMCredentials = Google::Apis::IamcredentialsV1
        #     iam_client = IAMCredentials::IAMCredentialsService.new
        #
        #     # Get the environment configured authorization
        #     scopes = ["https://www.googleapis.com/auth/iam"]
        #     iam_client.authorization = Google::Auth.get_application_default scopes
        #
        #     request = Google::Apis::IamcredentialsV1::SignBlobRequest.new(
        #       payload: string_to_sign
        #     )
        #     resource = "projects/-/serviceAccounts/#{issuer}"
        #     response = iam_client.sign_service_account_blob resource, request
        #     response.signed_blob
        #   end
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png", skip_lookup: true
        #   url = file.signed_url method: "GET", issuer: issuer,
        #                         signer: signer
        #
        def signed_url method: "GET",
                       expires: nil,
                       content_type: nil,
                       content_md5: nil,
                       headers: nil,
                       issuer: nil,
                       client_email: nil,
                       signing_key: nil,
                       private_key: nil,
                       signer: nil,
                       query: nil,
                       scheme: "HTTPS",
                       virtual_hosted_style: nil,
                       bucket_bound_hostname: nil,
                       version: nil
          ensure_service!
          version ||= :v2
          case version.to_sym
          when :v2
            sign = File::SignerV2.from_file self
            sign.signed_url method: method,
                            expires: expires,
                            headers: headers,
                            content_type: content_type,
                            content_md5: content_md5,
                            issuer: issuer,
                            client_email: client_email,
                            signing_key: signing_key,
                            private_key: private_key,
                            signer: signer,
                            query: query
          when :v4
            sign = File::SignerV4.from_file self
            sign.signed_url method: method,
                            expires: expires,
                            headers: headers,
                            issuer: issuer,
                            client_email: client_email,
                            signing_key: signing_key,
                            private_key: private_key,
                            signer: signer,
                            query: query,
                            scheme: scheme,
                            virtual_hosted_style: virtual_hosted_style,
                            bucket_bound_hostname: bucket_bound_hostname
          else
            raise ArgumentError, "version '#{version}' not supported"
          end
        end

        ##
        # The {File::Acl} instance used to control access to the file.
        #
        # A file has owners, writers, and readers. Permissions can be granted to
        # an individual user's email address, a group's email address,  as well
        # as many predefined lists.
        #
        # @see https://cloud.google.com/storage/docs/access-control Access
        #   Control guide
        #
        # @return [File::Acl]
        #
        # @example Grant access to a user by prepending `"user-"` to an email:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #
        #   email = "heidi@example.net"
        #   file.acl.add_reader "user-#{email}"
        #
        # @example Grant access to a group by prepending `"group-"` to an email:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #
        #   email = "authors@example.net"
        #   file.acl.add_reader "group-#{email}"
        #
        # @example Or, grant access via a predefined permissions list:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-todo-app"
        #   file = bucket.file "avatars/heidi/400x400.png"
        #
        #   file.acl.public!
        #
        def acl
          @acl ||= File::Acl.new self
        end

        ##
        # Reloads the file with current data from the Storage service.
        #
        # @param [Boolean, Integer] generation Specify a version of the file to
        #   reload with. When `true`, it will reload the version returned by
        #   {#generation}. The default behavior is to reload with the latest
        #   version of the file (regardless of the version to which the file is
        #   set, which is the version returned by {#generation}.)
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext"
        #   file.reload!
        #
        # @example The file's generation can used by passing `true`:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext", generation: 123456
        #   file.reload! generation: true
        #
        # @example A generation can also be specified:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #
        #   file = bucket.file "path/to/my-file.ext", generation: 123456
        #   file.reload! generation: 123457
        #
        def reload! generation: nil
          generation = self.generation if generation == true
          ensure_service!
          @gapi = service.get_file bucket, name, generation: generation,
                                                 user_project: user_project
          # If NotFound then lazy will never be unset
          @lazy = nil
          self
        end
        alias refresh! reload!

        ##
        # Determines whether the file exists in the Storage service.
        def exists?
          # Always true if we have a grpc object
          return true unless lazy?
          # If we have a value, return it
          return @exists unless @exists.nil?
          ensure_gapi!
          @exists = true
        rescue Google::Cloud::NotFoundError
          @exists = false
        end

        ##
        # @private
        # Determines whether the file was created without retrieving the
        # resource record from the API.
        def lazy?
          @lazy
        end

        ##
        # @private URI of the location and file name in the format of
        # <code>gs://my-bucket/file-name.json</code>.
        def to_gs_url
          "gs://#{bucket}/#{name}"
        end

        ##
        # @private New File from a Google API Client object.
        def self.from_gapi gapi, service, user_project: nil
          new.tap do |f|
            f.gapi = gapi
            f.service = service
            f.user_project = user_project
          end
        end

        ##
        # @private New lazy Bucket object without making an HTTP request.
        def self.new_lazy bucket, name, service, generation: nil,
                          user_project: nil
          # TODO: raise if name is nil?
          new.tap do |f|
            f.gapi.bucket = bucket
            f.gapi.name = name
            f.gapi.generation = generation
            f.service = service
            f.user_project = user_project
            f.instance_variable_set :@lazy, true
          end
        end

        ##
        # @private
        #
        def self.gapi_from_attrs gapi, attributes
          attributes.flatten!
          return nil if attributes.empty?
          attr_params = Hash[attributes.map do |attr|
                               [attr, gapi.send(attr)]
                             end]
          # Sending nil metadata results in an Apiary runtime error:
          # NoMethodError: undefined method `each' for nil:NilClass
          attr_params.reject! { |k, v| k == :metadata && v.nil? }
          Google::Apis::StorageV1::Object.new(**attr_params)
        end

        protected

        ##
        # Raise an error unless an active service is available.
        def ensure_service!
          raise "Must have active connection" unless service
        end

        ##
        # Ensures the Google::Apis::StorageV1::Bucket object exists.
        def ensure_gapi!
          ensure_service!
          return unless lazy?
          reload! generation: true
        end

        def update_gapi! attributes,
                         generation: nil,
                         if_generation_match: nil,
                         if_generation_not_match: nil,
                         if_metageneration_match: nil,
                         if_metageneration_not_match: nil,
                         override_unlocked_retention: nil
          attributes = Array(attributes)
          attributes.flatten!
          return if attributes.empty?
          update_gapi = self.class.gapi_from_attrs @gapi, attributes
          return if update_gapi.nil?

          ensure_service!

          rewrite_attrs = [:storage_class, :kms_key_name]
          @gapi = if attributes.any? { |a| rewrite_attrs.include? a }
                    rewrite_gapi bucket,
                                 name,
                                 update_gapi,
                                 generation: generation,
                                 if_generation_match: if_generation_match,
                                 if_generation_not_match: if_generation_not_match,
                                 if_metageneration_match: if_metageneration_match,
                                 if_metageneration_not_match: if_metageneration_not_match,
                                 user_project: user_project
                  else
                    service.patch_file bucket,
                                       name,
                                       update_gapi,
                                       generation: generation,
                                       if_generation_match: if_generation_match,
                                       if_generation_not_match: if_generation_not_match,
                                       if_metageneration_match: if_metageneration_match,
                                       if_metageneration_not_match: if_metageneration_not_match,
                                       user_project: user_project,
                                       override_unlocked_retention: override_unlocked_retention
                  end
        end

        def rewrite_gapi bucket,
                         name,
                         updated_gapi,
                         new_bucket: nil,
                         new_name: nil,
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
                         encryption_key: nil,
                         new_encryption_key: nil,
                         new_kms_key: nil,
                         user_project: nil
          new_bucket ||= bucket
          new_name ||= name
          options = {
            acl: File::Acl.predefined_rule_for(acl),
            generation: generation,
            if_generation_match: if_generation_match,
            if_generation_not_match: if_generation_not_match,
            if_metageneration_match: if_metageneration_match,
            if_metageneration_not_match: if_metageneration_not_match,
            if_source_generation_match: if_source_generation_match,
            if_source_generation_not_match: if_source_generation_not_match,
            if_source_metageneration_match: if_source_metageneration_match,
            if_source_metageneration_not_match: if_source_metageneration_not_match,
            source_key: encryption_key,
            destination_key: new_encryption_key,
            destination_kms_key: new_kms_key,
            user_project: user_project
          }.delete_if { |_k, v| v.nil? }

          resp = service.rewrite_file \
            bucket, name, new_bucket, new_name, updated_gapi, **options
          until resp.done
            sleep 1
            retry_options = options.merge token: resp.rewrite_token
            resp = service.rewrite_file \
              bucket, name, new_bucket, new_name, updated_gapi, **retry_options
          end
          resp.resource
        end

        def fix_rewrite_args dest_bucket, dest_path
          if dest_path.nil?
            dest_path = dest_bucket
            dest_bucket = bucket
          end
          dest_bucket = dest_bucket.name if dest_bucket.respond_to? :name
          dest_path = dest_path.name if dest_path.respond_to? :name
          [dest_bucket, dest_path]
        end

        # rubocop:disable Style/MultipleComparison

        def verify_file! file, verify = :md5
          verify_md5    = verify == :md5    || verify == :all
          verify_crc32c = verify == :crc32c || verify == :all
          Verifier.verify_md5! self, file    if verify_md5    && md5
          Verifier.verify_crc32c! self, file if verify_crc32c && crc32c
          file
        end

        # rubocop:enable Style/MultipleComparison

        # @return [IO] Returns an IO object representing the file data. This
        #   will either be a `::File` object referencing the local file
        #   system or a StringIO instance.
        def gzip_decompress local_file
          if local_file.respond_to? :path
            gz = ::File.open Pathname(local_file).to_path, "rb" do |f|
              Zlib::GzipReader.new StringIO.new(f.read)
            end
            uncompressed_string = gz.read
            ::File.open Pathname(local_file).to_path, "w" do |f|
              f.write uncompressed_string
              f
            end
          else # local_file is StringIO
            local_file.rewind
            gz = Zlib::GzipReader.new StringIO.new(local_file.read)
            StringIO.new gz.read
          end
        end

        ##
        # Yielded to a block to accumulate changes for a patch request.
        class Updater < File
          # @private
          attr_reader :updates, :gapi

          ##
          # @private
          # Whitelist of Google::Apis::StorageV1::Object attributes to be
          # copied when File#copy or File#rewrite is called with
          # `force_copy_metadata: true`.
          COPY_ATTRS = [
            :cache_control,
            :content_disposition,
            :content_encoding,
            :content_language,
            :content_type,
            :metadata
          ].freeze

          ##
          # @private Create an Updater object.
          def initialize gapi
            super()
            @updates = []
            @gapi = gapi
            @metadata ||= @gapi.metadata.to_h.dup
          end

          ##
          # A hash of custom, user-provided web-safe keys and arbitrary string
          # values that will returned with requests for the file as
          # "x-goog-meta-" response headers.
          #
          # @return [Hash(String => String)]
          #
          def metadata
            @metadata
          end

          ##
          # Updates the hash of custom, user-provided web-safe keys and
          # arbitrary string values that will returned with requests for the
          # file as "x-goog-meta-" response headers.
          #
          # @param [Hash(String => String)] metadata The user-provided metadata,
          #   in key/value pairs.
          #
          def metadata= metadata
            @metadata = metadata
            @gapi.metadata = @metadata
            update_gapi! :metadata
          end

          ##
          # @private Make sure any metadata changes are saved
          def check_for_changed_metadata!
            return if @metadata == @gapi.metadata.to_h
            @gapi.metadata = @metadata
            update_gapi! :metadata
          end

          protected

          ##
          # Queue up all the updates instead of making them.
          def update_gapi! attribute
            @updates << attribute
            @updates.uniq!
          end
        end
      end
    end
  end
end
