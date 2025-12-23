# Release History

### 1.52.0 (2024-05-31)

#### Features

* support for hierarchical namespace (folders) ([#25967](https://github.com/googleapis/google-cloud-ruby/issues/25967)) 

### 1.51.0 (2024-04-25)

#### Features

* Respect custom endpoint for signed_url ([#25469](https://github.com/googleapis/google-cloud-ruby/issues/25469)) 

### 1.50.0 (2024-04-19)

#### Features

* Add support for soft deletion ([#25340](https://github.com/googleapis/google-cloud-ruby/issues/25340)) 
#### Bug Fixes

* Set configured univer_domain and endpoint when initializing through Service ([#25665](https://github.com/googleapis/google-cloud-ruby/issues/25665)) 

### 1.49.0 (2024-02-21)

#### Features

* Support of Managed Folders ([#24809](https://github.com/googleapis/google-cloud-ruby/issues/24809)) 

### 1.48.1 (2024-01-26)

#### Bug Fixes

* Raise an error on mismatching universe domain ([#24486](https://github.com/googleapis/google-cloud-ruby/issues/24486)) 

### 1.48.0 (2024-01-25)

#### Features

* Support for universe_domain ([#24449](https://github.com/googleapis/google-cloud-ruby/issues/24449)) 

### 1.47.0 (2024-01-09)

#### Features

* support for object lock / retention ([#23732](https://github.com/googleapis/google-cloud-ruby/issues/23732)) 

### 1.46.0 (2024-01-08)

#### Features

* support match_glob for Object.list 

### 1.45.0 (2023-11-06)

#### Features

* added autoclass v2.1 features ([#23483](https://github.com/googleapis/google-cloud-ruby/issues/23483)) 

### 1.44.0 (2022-11-02)

#### Features

* support autoclass 

### 1.43.0 (2022-09-30)

#### Features

* Add retry conformance test ([#18230](https://github.com/googleapis/google-cloud-ruby/issues/18230)) 

### 1.42.0 (2022-09-21)

#### Features

* send invocation_id header in all requests ([#19161](https://github.com/googleapis/google-cloud-ruby/issues/19161)) 

### 1.41.0 (2022-09-16)

#### Features

* add retry support for non-idempotent operations ([#19134](https://github.com/googleapis/google-cloud-ruby/issues/19134)) 
#### Bug Fixes

* Correct options checks in retry operations ([#19135](https://github.com/googleapis/google-cloud-ruby/issues/19135)) 
* Update api for bucket update ([#19110](https://github.com/googleapis/google-cloud-ruby/issues/19110)) 

### 1.40.0 (2022-09-13)

#### Features

* Update all patch bucket helper methods to accept preconditions ([#19117](https://github.com/googleapis/google-cloud-ruby/issues/19117)) 

### 1.39.0 (2022-08-24)

#### Features

* add support for conditional idempotent operations ([#18834](https://github.com/googleapis/google-cloud-ruby/issues/18834)) 

### 1.38.0 (2022-07-31)

#### Features

* Add support for dual region gcs buckets ([#18862](https://github.com/googleapis/google-cloud-ruby/issues/18862)) 

### 1.37.0 (2022-06-30)

#### Features

* support OLM Prefix/Suffix ([#18190](https://github.com/googleapis/google-cloud-ruby/issues/18190)) 
* allow retry options to be configurable on client initialization ([#18332](https://github.com/googleapis/google-cloud-ruby/issues/18332)) 
#### Bug Fixes

* update object path parsing to handle hashes in them 

### 1.36.2 (2022-04-20)

#### Documentation

* Document support for dual region buckets

### 1.36.1 / 2022-02-08

#### Documentation

* Update the RPO sample output. ([#17277](https://www.github.com/googleapis/google-cloud-ruby/issues/17277))

### 1.36.0 / 2022-01-12

#### Features

* add support for RPO (turbo replication). ([#14407](https://www.github.com/googleapis/google-cloud-ruby/issues/14407))

### 1.35.0 / 2021-12-08

#### Features

* changed PAP unspecified to inherited
* support for more client timeout options

#### Bug Fixes

* Update dependency on the addressable gem to 2.8 to remediate a vulnerability

### 1.34.1 / 2021-07-08

#### Documentation

* Update AUTHENTICATION.md in handwritten packages

### 1.34.0 / 2021-06-30

#### Features

* Add support for automatic crc32c and md5 upload verification
  * Add checksum to Bucket#create_file

### 1.33.0 / 2021-06-29

#### Features

* Add support for PublicAccessPrevention
  * Add Bucket#public_access_prevention
  * Add Bucket#public_access_prevention=
  * Add Bucket#public_access_prevention_enforced?
  * Add Bucket#public_access_prevention_unspecified?
  * Add samples for PublicAccessPrevention

### 1.32.0 / 2021-06-22

#### Features

* Add sources_if_generation_match to Bucket#compose
* Add support for (meta)generation preconditions to File operations
  * Add if_(meta)generation_match options to Bucket#compose
  * Add if_(meta)generation_(not_)match options to Bucket#create_file
  * Add if_(meta)generation_(not_)match options to Bucket#file
  * Add if_(meta)generation_(not_)match options to File#delete.
  * Add if_(meta)generation_(not_)match options to File#rewrite
  * Add generation and if_(meta)generation_(not_)match options to File#update
  * Add generation and if_(meta)generation_(not_)match options to File::Acl predefined_acl methods

#### Bug Fixes

* Expand googleauth dependency to support future 1.x versions
* Update File::Verifier to test for File#to_path

### 1.31.1 / 2021-05-19

#### Documentation

* Update IAMCredentialsService#sign_service_account_blob examples

### 1.31.0 / 2021-03-10

#### Features

* Drop support for Ruby 2.4 and add support for Ruby 3.0

### 1.30.0 / 2021-01-13

#### Features

* Replace google-api-client with specific client gems
  * Remove google-api-client
  * Add google-apis-iamcredentials_v1
  * Add google-apis-storage_v1

#### Documentation

* Update Bucket#generate_signed_post_policy_v4 documentation

### 1.29.2 / 2020-12-14

#### Bug Fixes

* Fix support for #generate_signed_post_policy_v4 conditions

### 1.29.1 / 2020-10-05

#### Bug Fixes

* Fix encoding of space characters in file names in signed_url v4

#### Documentation

* Update Bucket#default_kms_key= docs
  * Demonstrate deleting the Cloud KMS encryption key
* Update customer-supplied encryption key docs and examples ([#7851](https://www.github.com/googleapis/google-cloud-ruby/issues/7851))

### 1.29.0 / 2020-09-22

#### Features

* quota_project can be set via library configuration ([#7656](https://www.github.com/googleapis/google-cloud-ruby/issues/7656))

#### Bug Fixes

* Fix encoding of space characters in #signed_url version: :v4
  * Fix encoding of space characters to use percent encoding (%20) instead of plus sign (+).

#### Documentation

* Add custom time to file metadata sample

### 1.28.0 / 2020-08-26

* Add Object Lifecycle Management fields
  * Add custom_time_before to Lifecycle::Rule
  * Add days_since_custom_time to Lifecycle::Rule
  * Add days_since_noncurrent_time to Lifecycle::Rule
  * Add noncurrent_time_before to Lifecycle::Rule
  * Add File#custom_time and #custom_time=

### 1.27.0 / 2020-07-29

#### Features

* Add support for signing URLs with IAMCredentials SignBlob API
  * Add signer parameter accepting Procs to the following methods:
    * Project#signed_url
    * Bucket#generate_signed_post_policy_v4
    * Bucket#post_object
    * Bucket#signed_url
    * File#signed_url
  * Update signer aliases signing_key and private_key to similarly support Procs

#### Documentation

* Update documentation of SignedUrlUnavailable

### 1.26.2 / 2020-05-28

#### Documentation

* Fix a few broken links

### 1.26.1 / 2020-05-06

#### Bug Fixes

* Add missing bucket condition in SignerV4#post_object
* Ensure bucket is not returned in PostObject fields

### 1.26.0 / 2020-04-06

#### Features

* Update V4 Signature support in Project#signed_url, Bucket#signed_url and File#signed_url
  * Add scheme, virtual_hosted_style and bucket_bound_hostname to #signed_url methods
  * Add support for V4 query param encoding and ordering
  * Convert tabs in V4 to single whitespace character
  * Set payload in V4 to X-Goog-Content-SHA256 if present
  * Fix method param default value GET for #signed_url
* Add support for V4 Signature POST Policies
  * Add Bucket#generate_signed_post_policy_v4

#### Bug Fixes

* Address keyword argument warnings in Ruby 2.7 and later

### 1.25.1 / 2020-01-06

#### Documentation

* Add ARCHIVE storage class

### 1.25.0 / 2019-12-12

#### Features

* Add IAM Conditions support to Policy

### 1.24.0 / 2019-11-12

#### Features

* Add force_copy_metadata to File#copy and #rewrite

#### Bug Fixes

* Update #post_object to support special variable `${filename}`

### 1.23.0 / 2019-11-05

#### Features

* Add support for Bucket#uniform_bucket_level_access
  * Deprecate Bucket#policy_only=, #policy_only?, and #policy_only_locked_at,
    which are now aliases for the uniform_bucket_level_access methods.

### 1.22.0 / 2019-10-28

* Now requires Ruby 2.4 or later.
* This release uses the updated default endpoint for Cloud Storage.

### 1.21.1 / 2019-09-30

#### Documentation

* update storage class examples in docs and tests
  * Replace MULTI_REGIONAL and REGIONAL with STANDARD and NEARLINE.

### 1.21.0 / 2019-08-16

#### Features

* Support overriding of service endpoint
* Update documentation

#### Bug Fixes

* Fix Bucket Policy Only service bug temporarily
  * Set UniformBucketLevelAccess to same value as BucketPolicyOnly

### 1.20.0 / 2019-08-08

* Add HmacKey
  * Add Project#create_hmac_key, Project#hmac_key, and Project#hmac_keys.
* Update documentation listings of current and legacy storage classes.
* Fix File#download to use generation from current File object.

### 1.19.0 / 2019-07-11

* Add Bucket#location_type
  * Remove :multi_regional and :regional from storage_class docs

### 1.18.2 / 2019-05-21

* Declare explicit dependency on mime-types

### 1.18.1 / 2019-04-29

* Update Storage Bucket Policy Only documentation.

### 1.18.0 / 2019-04-09

* Add support for V4 signed URLs.
  * Add version param to #signed_url.
* Fix file path encoding for V2 signed URLs.
  * Change CGI encoding to URI (percent) encoding to fix URLs containing spaces in file path.
* Fix documentation typo.

### 1.17.0 / 2019-02-07

* Add support for Bucket Policy Only with `Bucket#policy_only?`,
  `Bucket#policy_only=` and `Bucket#policy_only_locked_at`.
  Read more at https://cloud.google.com/storage/docs/bucket-policy-only

### 1.16.0 / 2019-02-01

* Make use of Credentials#project_id
  * Use Credentials#project_id
    If a project_id is not provided, use the value on the Credentials object.
    This value was added in googleauth 0.7.0.
  * Loosen googleauth dependency
    Allow for new releases up to 0.10.
    The googleauth devs have committed to maintaining the current API
    and will not make backwards compatible changes before 0.10.

### 1.15.0 / 2018-10-03

* Add Bucket retention policy
  * Add retention_policy fields and default_event_based_hold to Bucket.
  * Add retention_policy and hold fields to File.
  * Add Bucket#lock_retention_policy!
  * Add Bucket#metageneration.
  * Add Bucket#retention_policy_locked?
  * Add File#(set|release)_temporary_hold!
  * Add File#(set|release)_event_based_hold!

### 1.14.2 / 2018-09-20

* Update documentation.
  * Change documentation URL to googleapis GitHub org.
* Fix circular require warning.

### 1.14.1 / 2018-09-12

* Add missing documentation files to package.

### 1.14.0 / 2018-09-10

* Add Object Lifecycle Management:
  * Add Bucket#lifecycle.
  * Add Bucket::Lifecycle and Bucket::Lifecycle::Rule.
* Update documentation.

### 1.13.1 / 2018-08-21

* Update documentation.

### 1.13.0 / 2018-06-22

* Update Policy, protect from role duplication.
* Updated dependencies.

### 1.12.0 / 2018-05-09

* Support Cloud KMS keys / Customer-managed encryption keys (CMEK).

### 1.11.0 / 2018-05-01

* Support partial Storage::File downloads. (georgeclaghorn)
* Add File#rewrite.
  * Similar to File#copy, except for being able to specify both source and destination encryption keys.
  * Refactor both File#copy and File#rotate to call File#rewrite.
* Update documentation for File-like IO parameters. The underlying libraries call #size on the argument, which is not present on IO, but is present on File and StringIO.

### 1.10.0 / 2018-02-27

* Support Shared Configuration.
* Fix verification for gzipped files.
  * Add skip_decompress to File#download
  * Update documentation and examples for gzip-encoded files.
* Fix issue with IAM Policy not refreshing properly.
* Update Google API Client dependency.
* Update authentication documentation

### 1.9.0 / 2017-11-20

* Add `Google::Cloud::Storage.anonymous` to support public data access.

### 1.8.0 / 2017-11-14

* Add `Google::Cloud::Storage::Credentials` class.
* Rename constructor arguments to `project_id` and `credentials`.
  (The previous arguments `project` and `keyfile` are still supported.)
* Document `Google::Auth::Credentials` as `credentials` value.
* Updated `google-api-client`, `googleauth` dependencies.

### 1.7.1 / 2017-10-24

* Fix bug in Bucket#create_file, Bucket#compose, File#copy and File#rotate in
  which user_project was not set on returned File object.
* Fix bug in Bucket::Acl#add_reader and Bucket::Acl#add_owner in which
  user_project was not passed in the API request.

### 1.7.0 / 2017-10-18

* Add `Bucket#compose`.
* Update documentation.

### 1.6.0 / 2017-09-28

* Add `user_project` option to `Project#buckets` and `Project#create_bucket`.
* Upgrade to Google API Client 0.14.2.
* Update documentation.

### 1.5.0 / 2017-09-26

* Add Pub/Sub notification subscriptions.
* Update `#signed_url` to support symbols (dimroc).

### 1.4.0 / 2017-08-02

* Add `skip_lookup` option for retrieving `Bucket` and `File` objects
  without accessing the Storage API
  * Add `Bucket#exists?` method
  * Add `File#exists?` method
* Add `File#generations` method
  * Add `generation` argument to `File#delete`
  * Add `generation` argument to `File#reload!`
* Add `Bucket#storage_class=` method
* Fix for when the `user_project` value set on a `Bucket` was not being
  properly set on all `File` objects returned by `Bucket`.
* Fix to use `user_project` value when reloading a `Bucket`.

### 1.3.0 / 2017-07-11

* Add `query` parameter to `#signed_url` methods (georgeclaghorn).

### 1.2.0 / 2017-06-27

* Add Requester Pays support.
* Upgrade dependency on Google API Client.

### 1.1.0 / 2017-06-01

* Add Bucket#labels.
* Update gem spec homepage links.
* Remove memoization of Policy.
* Deprecate force parameter in Bucket#policy. (Will be removed in a future version.)
* Deprecate Policy#deep_dup. (Will be removed in a future version.)


### 1.0.1 / 2017-04-10

* Add Bucket IAM support

### 1.0.0 / 2017-04-05

* Release 1.0
* Improvements to File copy for large files
* Allow file attributes to be changed during copy
* Upgrade dependency on Google API Client

### 0.25.0 / 2017-03-31

* Allow upload and download of in-memory IO objects
* Added signed_url at top-level object, without creating a bucket or file object
* Updated documentation

### 0.24.0 / 2017-03-03

* Dependency on Google API Client has been updated to 0.10.x.

### 0.23.2 / 2017-02-21

* Allow setting a File's storage_class on file creation
* Allow updating an existing File's storage_class
* Add File#rotate to rotate encryption keys
* Add PostObject and Bucket#post_object for uploading via HTML forms

### 0.23.1 / 2016-12-12

* Support Google extension headers on signed URLs (calavera)

### 0.23.0 / 2016-12-8

* Remove `encryption_key_sha256` method parameter, hash will be calculated using `encryption_key`
* Many documentation improvements

### 0.21.0 / 2016-10-20

* New service constructor Google::Cloud::Storage.new
* Bucket#signed_url added to create URLs without a File object

### 0.20.2 / 2016-09-30

* Fix issue with signed_url and file names with spaces (gsbucks)

### 0.20.1 / 2016-09-02

* Fix for timeout on uploads.

### 0.20.0 / 2016-08-26

This gem contains the Google Cloud Storage service implementation for the `google-cloud` gem. The `google-cloud` gem replaces the old `gcloud` gem. Legacy code can continue to use the `gcloud` gem.

* Namespace is now `Google::Cloud`
* The `google-cloud` gem is now an umbrella package for individual gems
