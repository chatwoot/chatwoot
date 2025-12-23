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


require "google/cloud/storage/errors"
require "google/cloud/storage/service"
require "google/cloud/storage/convert"
require "google/cloud/storage/credentials"
require "google/cloud/storage/bucket"
require "google/cloud/storage/bucket/cors"
require "google/cloud/storage/bucket/lifecycle"
require "google/cloud/storage/file"
require "google/cloud/storage/hmac_key"

module Google
  module Cloud
    module Storage
      ##
      # # Project
      #
      # Represents the project that storage buckets and files belong to.
      # All data in Google Cloud Storage belongs inside a project.
      # A project consists of a set of users, a set of APIs, billing,
      # authentication, and monitoring settings for those APIs.
      #
      # Google::Cloud::Storage::Project is the main object for interacting with
      # Google Storage. {Google::Cloud::Storage::Bucket} objects are created,
      # read, updated, and deleted by Google::Cloud::Storage::Project.
      #
      # See {Google::Cloud#storage}
      #
      # @example
      #   require "google/cloud/storage"
      #
      #   storage = Google::Cloud::Storage.new
      #
      #   bucket = storage.bucket "my-bucket"
      #   file = bucket.file "path/to/my-file.ext"
      #
      class Project
        include Convert
        ##
        # @private The Service object.
        attr_accessor :service

        ##
        # @private Creates a new Project instance.
        #
        # See {Google::Cloud#storage}
        def initialize service
          @service = service
        end

        ##
        # The universe domain the client is connected to
        #
        # @return [String]
        #
        def universe_domain
          service.universe_domain
        end

        ##
        # The Storage project connected to.
        #
        # @return [String]
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new(
        #     project_id: "my-project",
        #     credentials: "/path/to/keyfile.json"
        #   )
        #
        #   storage.project_id #=> "my-project"
        #
        def project_id
          service.project
        end
        alias project project_id

        ##
        # The Google Cloud Storage managed service account created for the
        # project used to initialize the client library. (See also
        # {#project_id}.)
        #
        # @return [String] The service account email address.
        #
        def service_account_email
          @service_account_email ||= \
            service.project_service_account.email_address
        end

        ##
        # Add custom Google extension headers to the requests that use the signed URLs.
        #
        # @param [Hash] headers Google extension headers (custom HTTP headers that
        #   begin with `x-goog-`) to be included in requests that use the signed URLs.
        #   Provide headers as a key/value array, where the key is
        #   the header name, and the value is an array of header values.
        #   For headers with multiple values, provide values as a simple
        #   array, or a comma-separated string. For a reference of allowed
        #   headers, see [Reference Headers](https://cloud.google.com/storage/docs/xml-api/reference-headers).
        #
        # @return [Google::Cloud::Storage::Project] Returns the Project for method chaining
        #
        def add_custom_headers headers
          @service.add_custom_headers headers
          self
        end

        ##
        # Add custom Google extension header to the requests that use the signed URLs.
        #
        # @param [String] header_name Name of Google extension header (custom HTTP header that
        #   begin with `x-goog-`) to be included in requests that use the signed URLs.
        #   For a reference of allowed headers, see
        #   [Reference Headers](https://cloud.google.com/storage/docs/xml-api/reference-headers).
        # @param [Object] header_value Valid value of the Google extension header being added.
        #   For headers with multiple values, provide values as a simple array, or a comma-separated string.
        #
        # @return [Google::Cloud::Storage::Project] Returns the Project for method chaining
        #
        def add_custom_header header_name, header_value
          @service.add_custom_header header_name, header_value
          self
        end

        ##
        # Retrieves a list of buckets for the given project.
        #
        # @param [String] prefix Filter results to buckets whose names begin
        #   with this prefix.
        # @param [String] token A previously-returned page token representing
        #   part of the larger set of results to view.
        # @param [Integer] max Maximum number of buckets to return.
        # @param [Boolean, String] user_project If this parameter is set to
        #   `true`, transit costs for operations on the enabled buckets or their
        #   files will be billed to the current project for this client. (See
        #   {#project} for the ID of the current project.) If this parameter is
        #   set to a project ID other than the current project, and that project
        #   is authorized for the currently authenticated service account,
        #   transit costs will be billed to the given project. This parameter is
        #   required with requester pays-enabled buckets. The default is `nil`.
        #
        #   The value provided will be applied to all operations on the returned
        #   bucket instances and their files.
        #
        #   See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
        #
        # @return [Array<Google::Cloud::Storage::Bucket>] (See
        #   {Google::Cloud::Storage::Bucket::List})
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   buckets = storage.buckets
        #   buckets.each do |bucket|
        #     puts bucket.name
        #   end
        #
        # @example Retrieve buckets with names that begin with a given prefix:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   user_buckets = storage.buckets prefix: "user-"
        #   user_buckets.each do |bucket|
        #     puts bucket.name
        #   end
        #
        # @example Retrieve all buckets: (See {Bucket::List#all})
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   buckets = storage.buckets
        #   buckets.all do |bucket|
        #     puts bucket.name
        #   end
        #
        def buckets prefix: nil, token: nil, max: nil, user_project: nil
          gapi = service.list_buckets \
            prefix: prefix, token: token, max: max, user_project: user_project
          Bucket::List.from_gapi \
            gapi, service, prefix, max, user_project: user_project
        end
        alias find_buckets buckets

        ##
        # Retrieves bucket by name.
        #
        # @param [String] bucket_name Name of a bucket.
        # @param [Boolean] skip_lookup Optionally create a Bucket object
        #   without verifying the bucket resource exists on the Storage service.
        #   Calls made on this object will raise errors if the bucket resource
        #   does not exist. Default is `false`.
        # @param [Integer] if_metageneration_match Makes the operation conditional
        #   on whether the bucket's current metageneration matches the given value.
        # @param [Integer] if_metageneration_not_match Makes the operation
        #   conditional on whether the bucket's current metageneration does not
        #   match the given value.
        # @param [Boolean, String] user_project If this parameter is set to
        #   `true`, transit costs for operations on the requested bucket or a
        #   file it contains will be billed to the current project for this
        #   client. (See {#project} for the ID of the current project.) If this
        #   parameter is set to a project ID other than the current project, and
        #   that project is authorized for the currently authenticated service
        #   account, transit costs will be billed to the given project. This
        #   parameter is required with requester pays-enabled buckets. The
        #   default is `nil`.
        #
        #   The value provided will be applied to all operations on the returned
        #   bucket instance and its files.
        #
        #   See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
        #
        # @return [Google::Cloud::Storage::Bucket, nil] Returns nil if bucket
        #   does not exist
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "my-bucket"
        #   puts bucket.name
        #
        # @example With `user_project` set to bill costs to the default project:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "other-project-bucket", user_project: true
        #   files = bucket.files # Billed to current project
        #
        # @example With `user_project` set to a project other than the default:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.bucket "other-project-bucket",
        #                           user_project: "my-other-project"
        #   files = bucket.files # Billed to "my-other-project"
        #
        def bucket bucket_name,
                   skip_lookup: false,
                   if_metageneration_match: nil,
                   if_metageneration_not_match: nil,
                   user_project: nil
          if skip_lookup
            return Bucket.new_lazy bucket_name, service,
                                   user_project: user_project
          end
          gapi = service.get_bucket bucket_name,
                                    if_metageneration_match: if_metageneration_match,
                                    if_metageneration_not_match: if_metageneration_not_match,
                                    user_project: user_project
          Bucket.from_gapi gapi, service, user_project: user_project
        rescue Google::Cloud::NotFoundError
          nil
        end
        alias find_bucket bucket

        ##
        # Creates a new bucket with optional attributes. Also accepts a block
        # for defining the CORS configuration for a static website served from
        # the bucket. See {Bucket::Cors} for details.
        #
        # The API call to create the bucket may be retried under certain
        # conditions. See {Google::Cloud#storage} to control this behavior.
        #
        # You can pass [website
        # settings](https://cloud.google.com/storage/docs/website-configuration)
        # for the bucket, including a block that defines CORS rule. See
        # {Bucket::Cors} for details.
        #
        # Before enabling uniform bucket-level access (see
        # {Bucket#uniform_bucket_level_access=}) please review [uniform bucket-level
        # access](https://cloud.google.com/storage/docs/uniform-bucket-level-access).
        #
        # @see https://cloud.google.com/storage/docs/cross-origin Cross-Origin
        #   Resource Sharing (CORS)
        # @see https://cloud.google.com/storage/docs/website-configuration How
        #   to Host a Static Website
        #
        # @param [String] bucket_name Name of a bucket.
        # @param [String] acl Apply a predefined set of access controls to this
        #   bucket.
        #
        #   Acceptable values are:
        #
        #   * `auth`, `auth_read`, `authenticated`, `authenticated_read`,
        #     `authenticatedRead` - Project team owners get OWNER access, and
        #     allAuthenticatedUsers get READER access.
        #   * `private` - Project team owners get OWNER access.
        #   * `project_private`, `projectPrivate` - Project team members get
        #     access according to their roles.
        #   * `public`, `public_read`, `publicRead` - Project team owners get
        #     OWNER access, and allUsers get READER access.
        #   * `public_write`, `publicReadWrite` - Project team owners get OWNER
        #     access, and allUsers get WRITER access.
        # @param [String] default_acl Apply a predefined set of default object
        #   access controls to this bucket.
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
        # @param [String] location The location of the bucket. Optional.
        #   If not passed, the default location, 'US', will be used.
        #   If specifying a dual-region location, the `customPlacementConfig`
        #   property should be set in conjunction. See:
        #   [Storage Locations](https://cloud.google.com/storage/docs/locations).
        # @param [String] logging_bucket The destination bucket for the bucket's
        #   logs. For more information, see [Access
        #   Logs](https://cloud.google.com/storage/docs/access-logs).
        # @param [String] logging_prefix The prefix used to create log object
        #   names for the bucket. It can be at most 900 characters and must be a
        #   [valid object
        #   name](https://cloud.google.com/storage/docs/bucket-naming#objectnames)
        #   . By default, the object prefix is the name of the bucket for which
        #   the logs are enabled. For more information, see [Access
        #   Logs](https://cloud.google.com/storage/docs/access-logs).
        # @param [Symbol, String] storage_class Defines how objects in the
        #   bucket are stored and determines the SLA and the cost of storage.
        #   Accepted values include `:standard`, `:nearline`, `:coldline`, and
        #   `:archive`, as well as the equivalent strings returned by
        #   {Bucket#storage_class}. For more information, see [Storage
        #   Classes](https://cloud.google.com/storage/docs/storage-classes). The
        #   default value is the `:standard` storage class.
        # @param [Boolean] versioning Whether [Object
        #   Versioning](https://cloud.google.com/storage/docs/object-versioning)
        #   is to be enabled for the bucket. The default value is `false`.
        # @param [String] website_main The index page returned from a static
        #   website served from the bucket when a site visitor requests the top
        #   level directory. For more information, see [How to Host a Static
        #   Website
        #   ](https://cloud.google.com/storage/docs/website-configuration#step4).
        # @param [String] website_404 The page returned from a static website
        #   served from the bucket when a site visitor requests a resource that
        #   does not exist. For more information, see [How to Host a Static
        #   Website
        #   ](https://cloud.google.com/storage/docs/website-configuration#step4).
        # @param [String] user_project If this parameter is set to a project ID
        #   other than the current project, and that project is authorized for
        #   the currently authenticated service account, transit costs will be
        #   billed to the given project. The default is `nil`.
        # @param [Boolean] autoclass_enabled The bucket's autoclass configuration.
        #   Buckets can have either StorageClass OLM rules or Autoclass, but
        #   not both. When Autoclass is enabled on a bucket, adding StorageClass
        #   OLM rules will result in failure. For more information, see
        #   [Autoclass](https://cloud.google.com/storage/docs/autoclass).
        #
        #   The value provided will be applied to all operations on the returned
        #   bucket instance and its files.
        #
        #   See also {Bucket#requester_pays=} and {Bucket#requester_pays}.
        # @param [Boolean] enable_object_retention
        #   When set to true, object retention is enabled for this bucket.
        #
        # @yield [bucket] a block for configuring the bucket before it is
        #   created
        # @yieldparam [Bucket] bucket the bucket object to be configured
        #
        # @return [Google::Cloud::Storage::Bucket]
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.create_bucket "my-bucket"
        #
        # @example
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.create_bucket "my-bucket", enable_object_retention: true
        #
        # @example Configure the bucket in a block:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket = storage.create_bucket "my-bucket" do |b|
        #     b.website_main = "index.html"
        #     b.website_404 = "not_found.html"
        #     b.requester_pays = true
        #     b.cors.add_rule ["http://example.org", "https://example.org"],
        #                      "*",
        #                      headers: ["X-My-Custom-Header"],
        #                      max_age: 300
        #
        #     b.lifecycle.add_set_storage_class_rule "COLDLINE", age: 10
        #   end
        #
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def create_bucket bucket_name,
                          acl: nil,
                          default_acl: nil,
                          location: nil,
                          custom_placement_config: nil,
                          storage_class: nil,
                          logging_bucket: nil,
                          logging_prefix: nil,
                          website_main: nil,
                          website_404: nil,
                          versioning: nil,
                          requester_pays: nil,
                          user_project: nil,
                          autoclass_enabled: false,
                          enable_object_retention: nil,
                          hierarchical_namespace: nil
          params = {
            name: bucket_name,
            location: location,
            custom_placement_config: custom_placement_config,
            hierarchical_namespace: hierarchical_namespace
          }.delete_if { |_, v| v.nil? }
          new_bucket = Google::Apis::StorageV1::Bucket.new(**params)
          storage_class = storage_class_for storage_class
          updater = Bucket::Updater.new(new_bucket).tap do |b|
            b.logging_bucket = logging_bucket unless logging_bucket.nil?
            b.logging_prefix = logging_prefix unless logging_prefix.nil?
            b.autoclass_enabled = autoclass_enabled
            b.storage_class = storage_class unless storage_class.nil?
            b.website_main = website_main unless website_main.nil?
            b.website_404 = website_404 unless website_404.nil?
            b.versioning = versioning unless versioning.nil?
            b.requester_pays = requester_pays unless requester_pays.nil?
            b.hierarchical_namespace = hierarchical_namespace unless hierarchical_namespace.nil?
          end
          yield updater if block_given?
          updater.check_for_changed_labels!
          updater.check_for_mutable_cors!
          updater.check_for_mutable_lifecycle!
          gapi = service.insert_bucket \
            new_bucket, acl: acl_rule(acl), default_acl: acl_rule(default_acl),
                        user_project: user_project,
                        enable_object_retention: enable_object_retention
          Bucket.from_gapi gapi, service, user_project: user_project
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        ##
        # Creates a new HMAC key.
        #
        # @param [String] service_account_email The email address of the service
        #   account. Used to create the HMAC key.
        # @param [String] project_id The project ID associated with
        #   `service_account_email`, if `service_account_email` belongs to a
        #   project other than the currently authenticated project. Optional. If
        #   not provided, the project ID for the current project will be used.
        # @param [String] user_project If this parameter is set to a project ID
        #   other than the current project, and that project is authorized for
        #   the currently authenticated service account, transit costs will be
        #   billed to the given project. The default is `nil`.
        #
        # @return [Google::Cloud::Storage::HmacKey]
        #
        def create_hmac_key service_account_email, project_id: nil,
                            user_project: nil
          gapi = service.create_hmac_key service_account_email,
                                         project_id: project_id,
                                         user_project: user_project
          HmacKey.from_gapi gapi, service, user_project: user_project
        end

        ##
        # Retrieves an HMAC key's metadata; the key's secret is not included in
        # the representation.
        #
        # @param [String] project_id The project ID associated with the
        #   `service_account_email` used to create the HMAC key, if the
        #   service account email belongs to a project other than the
        #   currently authenticated project. Optional. If not provided, the
        #   project ID for current project will be used.
        # @param [String] user_project If this parameter is set to a project ID
        #   other than the current project, and that project is authorized for
        #   the currently authenticated service account, transit costs will be
        #   billed to the given project. The default is `nil`.
        #
        # @return [Google::Cloud::Storage::HmacKey]
        #
        def hmac_key access_id, project_id: nil, user_project: nil
          gapi = service.get_hmac_key \
            access_id, project_id: project_id, user_project: user_project
          HmacKey.from_gapi_metadata gapi, service, user_project: user_project
        end

        ##
        # Retrieves a list of HMAC key metadata matching the criteria; the keys'
        # secrets are not included.
        #
        # @param [String] service_account_email
        #   If present, only keys for the given service account are returned.
        # @param [String] project_id The project ID associated with the
        #   `service_account_email` used to create the HMAC keys, if the
        #   service account email belongs to a project other than the
        #   currently authenticated project. Optional. If not provided, the
        #   project ID for current project will be used.
        # @param [Boolean] show_deleted_keys
        #   Whether to include keys in the `DELETED` state. The default value is
        #   false.
        # @param [String] token A previously-returned page token representing
        #   part of the larger set of results to view.
        # @param [Integer] max Maximum number of keys to return.
        # @param [String] user_project If this parameter is set to a project ID
        #   other than the current project, and that project is authorized for
        #   the currently authenticated service account, transit costs will be
        #   billed to the given project. The default is `nil`.
        #
        # @return [Google::Cloud::Storage::HmacKey]
        #
        def hmac_keys service_account_email: nil, project_id: nil,
                      show_deleted_keys: nil, token: nil, max: nil,
                      user_project: nil
          gapi = service.list_hmac_keys \
            max: max, token: token,
            service_account_email: service_account_email,
            project_id: project_id, show_deleted_keys: show_deleted_keys,
            user_project: user_project

          HmacKey::List.from_gapi \
            gapi, service,
            service_account_email: nil, show_deleted_keys: nil,
            max: max, user_project: user_project
        end

        ##
        # Generates a signed URL. See [Signed
        # URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
        # for more information.
        #
        # Generating a URL requires service account credentials, either by
        # connecting with a service account when calling
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
        # @param [String, nil] bucket Name of the bucket, or nil if URL for all
        #   buckets is desired.
        # @param [String] path Path to the file in Google Cloud Storage.
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
        #   {File#content_disposition=} and {File#content_type=}.)
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
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #   shared_url = storage.signed_url bucket_name, file_path
        #
        # @example Using the `expires` and `version` options:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #   shared_url = storage.signed_url bucket_name, file_path,
        #                                   expires: 300, # 5 minutes from now
        #                                   version: :v4
        #
        # @example Using the `issuer` and `signing_key` options:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #   issuer_email = "service-account@gcloud.com"
        #   key = OpenSSL::PKey::RSA.new "-----BEGIN PRIVATE KEY-----\n..."
        #   shared_url = storage.signed_url bucket_name, file_path,
        #                                   issuer: issuer_email,
        #                                   signing_key: key
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
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #   url = storage.signed_url bucket_name, file_path,
        #                            method: "GET", issuer: issuer,
        #                            signer: signer
        #
        # @example Using the `headers` option:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #   shared_url = storage.signed_url bucket_name, file_path,
        #                                   headers: {
        #                                     "x-goog-acl" => "private",
        #                                     "x-goog-meta-foo" => "bar,baz"
        #                                   }
        #
        # @example Generating a signed URL for resumable upload:
        #   require "google/cloud/storage"
        #
        #   storage = Google::Cloud::Storage.new
        #
        #   bucket_name = "my-todo-app"
        #   file_path = "avatars/heidi/400x400.png"
        #
        #   url = storage.signed_url bucket_name, file_path,
        #                            method: "POST",
        #                            content_type: "image/png",
        #                            headers: {
        #                              "x-goog-resumable" => "start"
        #                            }
        #   # Send the `x-goog-resumable:start` header and the content type
        #   # with the resumable upload POST request.
        #
        def signed_url bucket,
                       path,
                       method: "GET",
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
          version ||= :v2
          case version.to_sym
          when :v2
            sign = File::SignerV2.new bucket, path, service
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
            sign = File::SignerV4.new bucket, path, service
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

        protected

        def acl_rule option_name
          Bucket::Acl.predefined_rule_for option_name
        end
      end
    end
  end
end
