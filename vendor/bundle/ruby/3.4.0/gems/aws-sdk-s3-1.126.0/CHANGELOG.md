Unreleased Changes
------------------

1.126.0 (2023-06-16)
------------------

* Feature - This release adds SDK support for request-payer request header and request-charged response header in the "GetBucketAccelerateConfiguration", "ListMultipartUploads", "ListObjects", "ListObjectsV2" and "ListObjectVersions" S3 APIs.

1.125.0 (2023-06-15)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.124.0 (2023-06-13)
------------------

* Feature - Integrate double encryption feature to SDKs.

1.123.2 (2023-06-12)
------------------

* Issue - Fix issue when decrypting noncurrent versions of objects when using client side encryption (#2866). 

1.123.1 (2023-06-02)
------------------

* Issue - Fix multipart `download_file` so that it does not download bytes out of range (#2859).

1.123.0 (2023-05-31)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.122.0 (2023-05-04)
------------------

* Feature - Documentation updates for Amazon S3

1.121.0 (2023-04-19)
------------------

* Feature - Provides support for "Snow" Storage class.

1.120.1 (2023-04-05)
------------------

* Issue - Skip `#check_for_cached_region` if custom endpoint provided

1.120.0 (2023-03-31)
------------------

* Feature - Documentation updates for Amazon S3

1.119.2 (2023-03-22)
------------------

* Issue - Provide `endpoint` and `bucket` attributes on `Aws::S3::Errors::PermanentRedirect` error objects.

1.119.1 (2023-02-13)
------------------

* Issue - Ensure object metadata is not lost on multipart copy (#2821).

1.119.0 (2023-01-26)
------------------

* Feature - Allow FIPS to be used with path-style URLs.

1.118.0 (2023-01-18)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Issue - Replace runtime endpoint resolution approach with generated ruby code.

1.117.2 (2022-11-30)
------------------

* Issue - Return error messages from failures in threads in `MultipartStreamUploader` (#2793).

1.117.1 (2022-10-26)
------------------

* Issue - Fix custom endpoint and port regression with `presigned_url` (#2776).

1.117.0 (2022-10-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Issue - Apply checksums to MultipartStreamUploader (#2769).

1.116.0 (2022-10-21)
------------------

* Feature - S3 on Outposts launches support for automatic bucket-style alias. You can use the automatic access point alias instead of an access point ARN for any object-level operation in an Outposts bucket.

1.115.0 (2022-10-19)
------------------

* Feature - Updates internal logic for constructing API endpoints. We have added rule-based endpoints and internal model parameters.

1.114.0 (2022-05-03)
------------------

* Feature - Documentation only update for doc bug fixes for the S3 API docs.

1.113.2 (2022-04-26)
------------------

* Issue - Fix an issue where `ExpiredToken` errors were retried as if the request was from another region.

1.113.1 (2022-04-25)
------------------

* Issue - Rewind the underlying file on a streaming retry that is not a truncated body (#2692).

1.113.0 (2022-02-24)
------------------

* Feature - This release adds support for new integrity checking capabilities in Amazon S3. You can choose from four supported checksum algorithms for data integrity checking on your upload and download requests. In addition, AWS SDK can automatically calculate a checksum as it streams data into S3

1.112.0 (2022-02-03)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.111.3 (2022-01-24)
------------------

* Issue - Fix starts_with fields on `PresignedPost` (#2636).

1.111.2 (2022-01-20)
------------------

* Issue - Minor cleanups.

1.111.1 (2022-01-06)
------------------

* Issue - Don't fail small files in `upload_file` when `:thread_count` is set. (#2628)

1.111.0 (2022-01-04)
------------------

* Feature - Minor doc-based updates based on feedback bugs received.

1.110.0 (2021-12-21)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.109.0 (2021-11-30)
------------------

* Feature - Introduce Amazon S3 Glacier Instant Retrieval storage class and a new setting in S3 Object Ownership to disable ACLs for bucket and the objects in it.

1.108.0 (2021-11-29)
------------------

* Feature - Amazon S3 Event Notifications adds Amazon EventBridge as a destination and supports additional event types. The PutBucketNotificationConfiguration API can now skip validation of Amazon SQS, Amazon SNS and AWS Lambda destinations.

1.107.0 (2021-11-23)
------------------

* Feature - Introduce two new Filters to S3 Lifecycle configurations - ObjectSizeGreaterThan and ObjectSizeLessThan. Introduce a new way to trigger actions on noncurrent versions by providing the number of newer noncurrent versions along with noncurrent days.

1.106.0 (2021-11-17)
------------------

* Feature - Add `presigned_request` method to `Aws::S3::Object`.

1.105.1 (2021-11-05)
------------------

* Issue - Raise error when `use_fips_endpoint` is used with `use_accelerate_endpoint`.

1.105.0 (2021-11-04)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.104.0 (2021-10-18)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.103.0 (2021-09-16)
------------------

* Feature - Add support for access point arn filtering in S3 CW Request Metrics

1.102.0 (2021-09-02)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.101.0 (2021-09-01)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.100.0 (2021-08-27)
------------------

* Feature - Documentation updates for Amazon S3.

1.99.0 (2021-08-16)
------------------

* Feature - Documentation updates for Amazon S3

1.98.0 (2021-07-30)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.97.0 (2021-07-28)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.96.2 (2021-07-20)
------------------

* Issue - Fix file downloading edge case for 1 byte multipart ranges (#2561).

1.96.1 (2021-06-10)
------------------

* Issue - fix GetBucketLocation location_constraint XML parsing (#2536)

1.96.0 (2021-06-03)
------------------

* Feature - S3 Inventory now supports Bucket Key Status

1.95.1 (2021-05-24)
------------------

* Issue - Raise an error when FIPS is in the ARN's region for Access Point and Object Lambda.

1.95.0 (2021-05-21)
------------------

* Feature - Documentation updates for Amazon S3

1.94.1 (2021-05-05)
------------------

* Issue - Expose presigned request status to the request handler stack #2513

1.94.0 (2021-04-27)
------------------

* Feature - Allow S3 Presigner to sign non http verbs like (upload_part, multipart_upload_abort, etc.) #2511

1.93.1 (2021-04-12)
------------------

* Issue - Fix FIPS and global endpoint behavior for S3 ARNs.

* Issue - Increases `multipart_threshold` default from 15 megabytes to 100 megabytes.

1.93.0 (2021-03-24)
------------------

* Feature - Documentation updates for Amazon S3

1.92.0 (2021-03-18)
------------------

* Feature - S3 Object Lambda is a new S3 feature that enables users to apply their own custom code to process the output of a standard S3 GET request by automatically invoking a Lambda function with a GET request

* Feature - Support S3 Object Lambda ARNs in the `bucket:` parameter.

1.91.0 (2021-03-10)
------------------

* Feature - Adding ID element to the CORSRule schema

1.90.0 (2021-03-08)
------------------

* Feature - Amazon S3 Documentation updates

1.89.0 (2021-02-26)
------------------

* Feature - Add RequestPayer to GetObjectTagging and PutObjectTagging.

1.88.2 (2021-02-25)
------------------

* Issue - Support https in `Object#public_url` for `virtual_host`. (#1389)

* Issue - Fix an issue with the IAD regional endpoint plugin removing `us-east-1` from custom endpoints.


1.88.1 (2021-02-12)
------------------

* Issue - Fixed an issue with some plugins expecting `#size` to exist on a request body for streaming IO.

1.88.0 (2021-02-02)
------------------

* Feature - Support PrivateLink using the client `:endpoint` option. This patch has a minor behavioral change: a client constructed using `:use_dualstack_endpoint` or `:use_accelerate_endpoint` and `:endpoint` will now raise an `ArgumentError`.

* Issue - Fix a bug where bucket region detection did not work correctly with ARNs.

1.87.0 (2020-12-21)
------------------

* Feature - Format GetObject's Expires header to be an http-date instead of iso8601

1.86.2 (2020-12-14)
------------------

* Issue - Use `URI::DEFAULT_PARSER.escape` (an alias for `URI.escape`) in the legacy signer because Ruby 3 removes WEBrick from stdlib.

1.86.1 (2020-12-11)
------------------

* Issue - Bump minimum KMS dependency. (#2449)

1.86.0 (2020-12-01)
------------------

* Feature - S3 adds support for multiple-destination replication, option to sync replica modifications;  S3 Bucket Keys to reduce cost of S3 SSE with AWS KMS

1.85.0 (2020-11-20)
------------------

* Feature - Add new documentation regarding automatically generated Content-MD5 headers when using the SDK or CLI.

1.84.1 (2020-11-10)
------------------

* Issue - Fix presigned urls for Outpost ARNs.

1.84.0 (2020-11-09)
------------------

* Feature - S3 Intelligent-Tiering adds support for Archive and Deep Archive Access tiers; S3 Replication adds replication metrics and failure notifications, brings feature parity for delete marker replication

1.83.2 (2020-11-06)
------------------

* Issue - Fix bug with clients not resolving the correct endpoint in `us-east-1` using access point ARNs.

1.83.1 (2020-10-19)
------------------

* Issue - Fix `multipart_threshold` documentation.

1.83.0 (2020-10-02)
------------------

* Feature - Amazon S3 Object Ownership is a new S3 feature that enables bucket owners to automatically assume ownership of objects that are uploaded to their buckets by other AWS Accounts.

1.82.0 (2020-09-30)
------------------

* Feature - Amazon S3 on Outposts expands object storage to on-premises AWS Outposts environments, enabling you to store and retrieve objects using S3 APIs and features.

* Feature - Support Outpost Access Point ARNs.

1.81.1 (2020-09-25)
------------------

* Issue - Ignore `amz-sdk-request` header (used for standard and adaptive retries) in the pre-signer. (#2411)

1.81.0 (2020-09-15)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.80.0 (2020-09-10)
------------------

* Feature - Bucket owner verification feature added. This feature introduces the x-amz-expected-bucket-owner and x-amz-source-expected-bucket-owner headers.

1.79.1 (2020-08-26)
------------------

* Issue - Fix `Aws::S3::PresignedPost` using the `use_accelerate_endpoint` option with Resource clients. (#2103)

1.79.0 (2020-08-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.78.0 (2020-08-11)
------------------

* Feature - Add support for in-region CopyObject and UploadPartCopy through S3 Access Points

1.77.0 (2020-08-10)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Issue - Fix issue with JRuby and bump minimum version of core.

1.76.0 (2020-08-07)
------------------

* Feature - Updates Amazon S3 API reference documentation.

* Feature - Updates to the Amazon S3 Encryption Client. This change includes fixes for issues that were reported by Sophie Schmieg from the Google ISE team, and for issues that were discovered by AWS Cryptography.

1.75.0 (2020-07-21)
------------------

* Feature - Add progress_callback to `Object#upload` to support reporting of upload progress. (#648)

1.74.0 (2020-07-08)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Feature - Allow the `use_accelerate_endpoint` option to be used with `Aws::S3::PresignedPost`. (#2103)

1.73.0 (2020-07-02)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.72.0 (2020-06-26)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.71.1 (2020-06-25)
------------------

* Issue - Fix uninitialized constant `Aws::S3::Plugins::RetryableBlockIO::Forwardable` (#2348)

1.71.0 (2020-06-25)
------------------

* Issue - This version has been yanked. (#2349).
* Feature - Retry incomplete, streaming responses to `get_object` using the range parameter to avoid re-downloading already processed data (#2326).
* Issue - Reduce memory usage of `IOEncryptor` and `IODecryptor`.

1.70.0 (2020-06-23)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.69.1 (2020-06-22)
------------------

* Issue - Add support for user provided encryption context to `EncryptionV2::Client`.

1.69.0 (2020-06-18)
------------------

* Feature - Add a new version of the S3 Client Side Encryption Client: `EncryptionV2::Client` which supports more modern encryption algorithms.

1.68.1 (2020-06-11)
------------------

* Issue - Republish previous version with correct dependency on `aws-sdk-core`.

1.68.0 (2020-06-10)
------------------

* Issue - This version has been yanked. (#2327).
* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Feature - Change `:compute_checksums` option to compute checksums only for optional operations when set to true, and no operations when set to false. Operations that require checksums are now modeled with `httpChecksumRequired` and computed automatically in aws-sdk-core.

1.67.1 (2020-06-01)
------------------

* Issue - Add support for Object.exists? and Waiters for the encryption client.

1.67.0 (2020-05-28)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.66.0 (2020-05-21)
------------------

* Feature - Deprecates unusable input members bound to Content-MD5 header. Updates example and documentation.

1.65.0 (2020-05-18)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Feature - Allow S3 presigner to presign non-object operations such as `list_objects`.

1.64.0 (2020-05-07)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.63.1 (2020-05-04)
------------------

* Issue - Handle copy_object, complete_multipart_upload, and upload_part_copy http responses with 200 OK and incomplete bodies as errors.

1.63.0 (2020-04-22)
------------------

* Feature - Add `presigned_request` method to the `Presigner` class. This method returns a URL and headers necessary rather than hoisting them onto the query string.
* Feature - Force HTTPS when using `virtual_host: true` on the `Presigner` class.

1.62.0 (2020-04-20)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.61.2 (2020-04-03)
------------------

* Issue - Add `put_bucket_lifecycle_configuration` and `put_bucket_replication` as required operations used in the MD5 plugin.

1.61.1 (2020-03-10)
------------------

* Issue - Fix raising in `Object#upload_stream` block not triggering the `Aws::S3::MultipartStreamUploader#abort_upload`.

1.61.0 (2020-03-09)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.
* Issue - Don't update endpoint on region mismatch errors when using a custom endpoint.

1.60.2 (2020-02-07)
------------------

* Issue - Allow `Aws::S3::Encrypted::Client` to be used with a Resource client.

1.60.1 (2019-12-19)
------------------

* Issue - Allow downcased option for S3 us-east-1 regionalization.

1.60.0 (2019-12-18)
------------------

* Feature - Updates Amazon S3 endpoints allowing you to configure your client to opt-in to using S3 with the us-east-1 regional endpoint, instead of global.

1.59.1 (2019-12-17)
------------------

* Issue - Added validation in the s3 presigner to check for 0 or negative expire_in times.

1.59.0 (2019-12-05)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Issue - Fixed an issue with Access Point ARNs not resigning correctly.

* Issue - Fixed S3 gemspec to require a minimum core version to support S3 Access Point ARNs. (GitHub PR #2184)

1.58.0 (2019-12-03)
------------------

* Feature - Amazon S3 Access Points is a new S3 feature that simplifies managing data access at scale for shared data sets on Amazon S3. Access Points provide a customizable way to access the objects in a bucket, with a unique hostname and access policy that enforces the specific permissions and network controls for any request made through the access point. This represents a new way of provisioning access to shared data sets.

1.57.0 (2019-11-20)
------------------

* Feature - This release introduces support for Amazon S3 Replication Time Control, a new feature of S3 Replication that provides a predictable replication time backed by a Service Level Agreement. S3 Replication Time Control helps customers meet compliance or business requirements for data replication, and provides visibility into the replication process with new Amazon CloudWatch Metrics.

1.56.0 (2019-11-18)
------------------

* Feature - Added support for S3 Replication for existing objects. This release allows customers who have requested and been granted access to replicate existing S3 objects across buckets.

* Issue - Fix issue where `Aws::Errors::MissingRegionError` was not thrown for S3 or S3Control clients.

1.55.0 (2019-11-15)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.54.0 (2019-11-13)
------------------

* Feature - Support `:s3_us_east_1_regional_endpoint` with `regional` to enable IAD regional endpoint for S3.

1.53.0 (2019-10-31)
------------------

* Feature - S3 Inventory now supports a new field 'IntelligentTieringAccessTier' that reports the access tier (frequent or infrequent) of objects stored in Intelligent-Tiering storage class.

1.52.0 (2019-10-28)
------------------

* Feature - Adding support in SelectObjectContent for scanning a portion of an object specified by a scan range.

1.51.0 (2019-10-23)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.50.0 (2019-10-17)
------------------

* Feature - Add support to yield the response in #upload_file if a block is given.

1.49.0 (2019-10-10)
------------------

* Feature - Support `#delete_object` and `#head_object` for encryption client.

1.48.0 (2019-08-30)
------------------

* Feature - Added a `:whitelist_headers` option to S3 presigner.

1.47.0 (2019-08-28)
------------------

* Feature - Added a `:time` option to S3 presigner.

1.46.0 (2019-07-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.45.0 (2019-07-03)
------------------

* Feature - Add S3 x-amz-server-side-encryption-context support.

1.44.0 (2019-07-01)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.43.0 (2019-06-17)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.42.0 (2019-06-04)
------------------

* Feature - Documentation updates for s3

1.41.0 (2019-05-29)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.40.0 (2019-05-21)
------------------

* Feature - API update.

1.39.0 (2019-05-16)
------------------

* Feature - API update.

1.38.0 (2019-05-15)
------------------

* Feature - API update.

1.37.0 (2019-05-14)
------------------

* Feature - API update.

1.36.1 (2019-04-19)
------------------

* Issue - Reduce memory usage of `Aws::S3::Object#upload_stream` when `StringIO` is used

1.36.0 (2019-03-27)
------------------

* Feature - API update.

1.35.0 (2019-03-22)
------------------

* Feature - API update.

1.34.0 (2019-03-21)
------------------

* Feature - API update.

1.33.0 (2019-03-18)
------------------

* Feature - API update.

1.32.0 (2019-03-14)
------------------

* Feature - API update.

1.31.0 (2019-03-08)
------------------

* Feature - API update.

1.30.1 (2019-01-11)
------------------

* Issue - Plugin updates to support client-side monitoring.

1.30.0 (2018-12-04)
------------------

* Feature - API update.

1.29.0 (2018-11-30)
------------------

* Feature - API update.

1.28.0 (2018-11-29)
------------------

* Feature - API update.

* Issue - Update operations needs Content-MD5 header

1.27.0 (2018-11-27)
------------------

* Feature - API update.

1.26.0 (2018-11-26)
------------------

* Feature - API update.

1.25.0 (2018-11-20)
------------------

* Feature - API update.

1.24.1 (2018-11-16)
------------------

* Issue - Update version dependency on `aws-sdk-core` to support endpoint discovery.

1.24.0 (2018-11-15)
------------------

* Feature - API update.

1.23.1 (2018-10-30)
------------------

* Issue - Support multipart upload empty stream (GitHub Issue #1880)
* Issue - Aws::S3::Encryption::IOAuthDecrypter - Fixes issue where the body tag being split across packets could cause GCM decryption to fail intermittently.

1.23.0 (2018-10-24)
------------------

* Feature - API update.

1.22.0 (2018-10-23)
------------------

* Feature - API update.

1.21.0 (2018-10-04)
------------------

* Feature - API update.

1.20.0 (2018-09-19)
------------------

* Feature - API update.

1.19.0 (2018-09-06)
------------------

* Feature - Adds code paths and plugins for future SDK instrumentation and telemetry.

1.18.0 (2018-09-05)
------------------

* Feature - API update.

1.17.1 (2018-08-29)
------------------

* Issue - Update example for bucket#url (Github Issue#1868)

* Issue - Support opt-out counting #presigned_url as #api_requests (Github Issue#1866)

1.17.0 (2018-07-11)
------------------

* Feature - API update.

1.16.1 (2018-07-10)
------------------

* Issue - Avoids region redirects for FIPS endpoints

1.16.0 (2018-06-28)
------------------

* Feature - Supports `:version_id` for resource `#download_file` helper.

* Issue - Reduce memory allocation in checksum and signature generation.

* Issue - Ensure file handlers are closed when an exception is raised in `Aws::S3::FileUploader`.

1.15.0 (2018-06-26)
------------------

* Feature - API update.

1.14.0 (2018-06-13)
------------------

* Feature - Adds support for `Aws::S3::Object#upload_stream`, allowing streaming uploads outside of a File-based interface.

1.13.0 (2018-05-22)
------------------

* Feature - API update.

* Issue - Update EventEmitter to Aws::EventEmitter

1.12.0 (2018-05-18)
------------------

* Feature - API update.

1.11.0 (2018-05-17)
------------------

* Feature - Support S3 `SelectObjectContent` API

1.10.0 (2018-05-07)
------------------

* Feature - API update.

1.9.1 (2018-04-19)
------------------

* Issue - S3 accelerate endpoint doesn't work with 'expect' header

1.9.0 (2018-04-04)
------------------

* Feature - API update.

1.8.2 (2018-02-23)
------------------

* Issue - Add support for AES/CBC/PKCS7Padding to encryption client.

1.8.1 (2018-02-16)
------------------

* Issue - Enhance S3 Multipart Downloader performance #1709

* Issue - Fix Ruby 2.5 warnings.

1.8.0 (2017-11-29)
------------------

* Feature - API update.

1.7.0 (2017-11-17)
------------------

* Feature - API update.

* Issue - Fix S3 unit test with latest endpoint

1.6.0 (2017-11-07)
------------------

* Feature - API update.

* Issue - Update S3 unit test with latest endpoint

1.5.0 (2017-10-06)
------------------

* Feature - API update.

* Issue - Update OJ Json parser error code
* Issue - Fix typo

1.4.0 (2017-09-14)
------------------

* Feature - API update.

1.3.0 (2017-09-13)
------------------

* Feature - API update.

1.2.0 (2017-09-07)
------------------

* Feature - API update.

1.1.0 (2017-09-01)
------------------

* Feature - API update.

* Issue - Add object streaming behavior smoke test

* Issue - Update `aws-sdk-s3` gemspec metadata.

1.0.0 (2017-08-29)
------------------

1.0.0.rc15 (2017-08-15)
------------------

* Feature - API update.

* Issue - Aws::S3 - Fix Multipart Downloader bug issue #1566, now file batches exist in a newly created tmp directory under destination directory.

1.0.0.rc14 (2017-08-01)
------------------

* Feature - API update.

1.0.0.rc13 (2017-07-25)
------------------

* Feature - API update.

1.0.0.rc12 (2017-07-13)
------------------

* Feature - API update.

1.0.0.rc11 (2017-07-06)
------------------

* Feature - API update.

1.0.0.rc10 (2017-06-29)
------------------

* Feature - API update.

1.0.0.rc9 (2017-06-26)
------------------

* Feature - API update.

1.0.0.rc8 (2017-05-23)
------------------

* Feature - API update.

1.0.0.rc7 (2017-05-09)
------------------

* Issue - Correct dependency on `aws-sdk-kms` gem.

1.0.0.rc6 (2017-05-09)
------------------

* Feature - API update.

1.0.0.rc5 (2017-05-05)
------------------

* Feature - Aws::S3 - Added Multipart Download Helper feature to support different `:mode` ("auto", "single_request", "get_range") in downloading large objects with `#download_file` in multipart when possible.

1.0.0.rc4 (2017-04-21)
------------------

* Feature - API update.

1.0.0.rc3 (2017-03-09)
------------------

* Issue - Correct dependency on `aws-sdk-kms` gem.

1.0.0.rc2 (2016-12-09)
------------------

* Feature - API update.

1.0.0.rc1 (2016-12-05)
------------------

* Feature - Initial preview release of the `aws-sdk-s3` gem.
