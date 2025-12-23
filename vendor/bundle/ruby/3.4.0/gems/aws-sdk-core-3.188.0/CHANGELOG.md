Unreleased Changes
------------------

3.188.0 (2023-11-22)
------------------

* Feature - AWS SDK for Ruby no longer supports Ruby runtime versions 2.3 and 2.4.

* Feature - Support `AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE` in `ECSCredentials` and also allow for ECS and EKS link-local http addresses.

3.187.1 (2023-11-20)
------------------

* Issue - For `awsQueryCompatible` services, default an empty list or map for shapes that were previously flattened in the query protocol.

3.187.0 (2023-11-17)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.186.0 (2023-11-02)
------------------

* Feature - Support disabling IMDSv1 in `InstanceProfileCredentials` using `ENV['AWS_EC2_METADATA_V1_DISABLED']`, `ec2_metadata_v1_disabled` shared config, or the `disable_imds_v1` credentials option.

3.185.2 (2023-10-31)
------------------

* Issue - Fix query string support to lists of booleans, floats, integers and timestamps per rest-json protocol.

3.185.1 (2023-10-05)
------------------

* Issue - Ignore `__type` when deserializing Unions.

3.185.0 (2023-10-02)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.184.0 (2023-09-27)
------------------

* Feature - Change the `ServiceError` data member from read only to read/write.

3.183.1 (2023-09-25)
------------------

* Issue - Remove value inspection from param validation errors.

3.183.0 (2023-09-20)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.182.0 (2023-09-19)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.181.1 (2023-09-14)
------------------

* Issue - Fix host label validation in endpoint matchers.

3.181.0 (2023-08-22)
------------------

* Feature - Add support for `on_chunk_received` callback.

3.180.3 (2023-08-09)
------------------

* Issue - Add support for sso-session names with whitespace configured by the CLI `aws sso configure` command (#2895).

3.180.2 (2023-08-07)
------------------

* Issue - Fix parsing of ini files with mixes of blank properties and nested configurations.

3.180.1 (2023-07-31)
------------------

* Issue - Remove checksums from default stubs (#2888).

3.180.0 (2023-07-25)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.179.0 (2023-07-24)
------------------

* Feature - Add `checksum_validated` method to response.

3.178.0 (2023-07-11)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add support for configuring the endpoint URL in the shared configuration file or via an environment variable for a specific AWS service or all AWS services.

3.177.0 (2023-07-06)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add support for Request Compression.

3.176.1 (2023-06-29)
------------------

* Issue - Fix signing for S3/S3 Control and `aws-crt` gem for certain object keys (#2849).

* Issue - Ensure `SSOCredentials` `#expiration` is a `Time` (#2874)

3.176.0 (2023-06-28)
------------------

* Feature - Add :expiration accessor to `CredentialProvider` and do not refresh credentials when checking expiration (#2872).

3.175.0 (2023-06-15)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.174.0 (2023-05-31)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Improve User-Agent metrics tracking.

3.173.1 (2023-05-24)
------------------

* Issue - Updated `checksum_algorithm` plugin to use IO.copy_stream for JRuby.

3.173.0 (2023-05-18)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.172.0 (2023-05-08)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Add :region option to `Aws::Log::Formatter`.

3.171.1 (2023-05-04)
------------------

* Issue - Fix error code parsing in AWS query compatible JSON services.

3.171.0 (2023-03-22)
------------------

* Feature - Add support for `AWS_CONTAINER_CREDENTIALS_FULL_URI` and `AWS_CONTAINER_AUTHORIZATION_TOKEN` environment variables to `ECSCredentials`.

3.170.1 (2023-03-17)
------------------

* Issue - Reduce memory usage in H2::Connection when `http_wire_log` is not set.

3.170.0 (2023-01-25)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.169.0 (2023-01-18)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Issue - Replace runtime endpoint resolution approach with generated ruby code for STS, SSO, and SSOOIDC.

3.168.4 (2022-12-08)
------------------

* Issue - Fix Sign to not sign Sigv2 requests to S3.

3.168.3 (2022-12-02)
------------------

* Issue - Retry S3's `BadDigest` error

3.168.2 (2022-11-29)
------------------

* Issue - Allow region resolution in `AssumeRoleCredentials` from `CredentialProviderChain`.

3.168.1 (2022-11-18)
------------------

* Issue - Fix initialization of SSOTokenProvider when `AWS_PROFILE` is specified.

3.168.0 (2022-11-17)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.167.0 (2022-11-09)
------------------

* Issue - Ensure the stream_thread is not killed before H2 connection status is updated (#2779).

* Feature - Add token refresh support to `SSOCredentialProvider`.

3.166.0 (2022-10-26)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.165.1 (2022-10-25)
------------------

* Issue - Require the SignatureV4 plugin to fix compatability with older `aws-sdk-s3` versions (#2774).

3.165.0 (2022-10-25)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add support for service gems to dynamically determine their own endpoints via modeling. Service gems now generate a plugin called "Endpoints" that defines configuration for EndpointProvider, a new public type, and any client config related to endpoints. Endpoint providers will resolve values using another new public type, Endpoint Parameters, generated for each service. The plugin will use the endpoint provider to resolve an endpoint and then apply it to the request prior to serialization. Endpoint providers can be composed to change endpoint resolution logic, i.e. for testing. In addition to endpoints, the endpoint provider may also override the authentication scheme (auth scheme) which details how the request should be signed for the endpoint. A new "Sign" plugin in core replaces the SignatureV4 plugin that will generically sign any type of auth scheme that a service might have.

3.164.0 (2022-10-21)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.163.0 (2022-10-20)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.162.0 (2022-10-19)
------------------

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.161.0 (2022-10-18)
------------------

* Feature - Support AwsQueryCompatible trait to read error code from x-amzn-query-error header.

3.160.0 (2022-10-13)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.159.0 (2022-10-07)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.158.1 (2022-10-06)
------------------

* Issue - Ensure that the ReadCallbackIO is always unwrapped (#2761).

3.158.0 (2022-09-30)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.157.0 (2022-09-29)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.156.0 (2022-09-27)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.155.0 (2022-09-26)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.154.0 (2022-09-23)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.153.0 (2022-09-22)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.152.0 (2022-09-21)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.151.0 (2022-09-20)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.150.0 (2022-09-19)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.149.0 (2022-09-16)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.148.0 (2022-09-15)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.147.0 (2022-09-14)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.146.0 (2022-09-13)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.145.0 (2022-09-12)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.144.0 (2022-09-09)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.143.0 (2022-09-08)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.142.0 (2022-09-07)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.141.0 (2022-09-06)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.140.0 (2022-09-02)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.139.0 (2022-09-01)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.138.0 (2022-08-31)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.137.0 (2022-08-30)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Issue - Fix errors in recursion detection when `_X_AMZN_TRACE_ID` is unset (#2748).

3.136.0 (2022-08-25)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Updated Aws::SSOOIDC::Client with the latest API changes.

3.135.0 (2022-08-24)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.134.0 (2022-08-23)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add support for Bearer Token Authentication and TokenProviders.

* Issue - Validate that `_X_AMZN_TRACE_ID` ENV value contains only valid, non-control characters.

3.133.0 (2022-08-22)
------------------

* Feature - Moved functionality from `aws-sdk-ssooidc` into core.

3.132.0 (2022-08-08)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.131.6 (2022-08-03)
------------------

* Issue - Fix typo in `RecursionDetection`, change amz to amzn in header and env name.

3.131.5 (2022-07-28)
------------------

* Issue - Fix `to_json` usage in nested hashes by defining `as_json` (#2733).

3.131.4 (2022-07-27)
------------------

* Issue - Fix `to_json` usage on pageable responses when using Rails (#2733).
* Issue - Use `expand_path` on credential/config paths in SharedConfig (#2735).

3.131.3 (2022-07-18)
------------------

* Issue - Add support for serializing shapes on the body with `jsonvalue` members.

3.131.2 (2022-06-20)
------------------

* Issue - Populate context :request_id for XML error responses.

3.131.1 (2022-05-20)
------------------

* Issue - Bump the minimum version of `jmespath` dependency.

3.131.0 (2022-05-16)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.130.2 (2022-04-22)
------------------

* Issue - Don't pass `:before_refresh` to Client constructors in RefreshingCredential implementations (#2690).

3.130.1 (2022-04-12)
------------------

* Issue - Don't call `refresh!` on non-refreshable `Credentials` when retrying errors (#2685).

3.130.0 (2022-03-11)
------------------

* Feature - Asynchronously refresh AWS credentials (#2641).

* Issue - Add x-amz-region-set to list of headers deleted for re-sign.

3.129.1 (2022-03-10)
------------------

* Issue - Make stubs thread safe by creating new responses for each operation call (#2675).

3.129.0 (2022-03-08)
------------------

* Feature - Add support for cases when `InstanceProfileCredentials` (IMDS) is unable to refresh credentials.

3.128.1 (2022-03-07)
------------------

* Issue - Fixed `Aws::PageableResponse` invalidating Ruby's global constant cache.

3.128.0 (2022-03-04)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.127.0 (2022-02-24)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Support `HttpChecksum` trait for requests and responses.

3.126.2 (2022-02-16)
------------------

* Issue - Add a before_refresh callback to AssumeRoleCredentials (#2529).
* Issue - Raise a `NoSuchProfileError` when config and credentials files don't exist.

3.126.1 (2022-02-14)
------------------

* Issue - Set `create_time` on IMDS tokens before fetch to reduce chance of using expired tokens and retry failures due to using expired tokens.

3.126.0 (2022-02-03)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add support for recursion detection.

3.125.6 (2022-02-02)
------------------

* Issue - Ensure default message for ServiceError is a string (#2643).

3.125.5 (2022-01-19)
------------------

* Issue - Correctly serialize empty header lists.

3.125.4 (2022-01-18)
------------------

* Issue - Add `InternalError` to `ErrorInspector` for S3 errors.


3.125.3 (2022-01-12)
------------------

* Issue - Add `ExpiredTokenException` to `ErrorInspector` for Kinesis errors.

3.125.2 (2022-01-10)
------------------

* Issue - Correctly serialize lists of strings in headers with quotes and commas.

3.125.1 (2022-01-04)
------------------

* Issue - Parse a response with consecutive spaces correctly when ox is used as the XML parser.

3.125.0 (2021-12-21)
------------------

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add `:defaults_mode` configuration - that determines how certain default configuration options are resolved in the SDK.

3.124.0 (2021-11-30)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.123.0 (2021-11-23)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.122.1 (2021-11-09)
------------------

* Issue - Correctly serialize/deserialize header lists.

3.122.0 (2021-11-04)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Issue - Fix parsing of ISO8601 timestamps with millisecond precision in headers.

* Feature - Support modeled dualstack endpoints. It can be configured with shared configuration (`use_dualstack_endpoint`), an ENV variable (`AWS_USE_DUALSTACK_ENDPOINT`), and a constructor option (`:use_dualstack_endpoint`). Requests made to services without a dualstack endpoint will fail.

* Feature - Support modeled fips endpoints. It can be configured with shared configuration (`use_fips_endpoint`), an ENV variable (`AWS_USE_FIPS_ENDPOINT`), and a constructor option (`:use_fips_endpoint`). Requests made to services without a fips endpoint will fail.

3.121.6 (2021-11-02)
------------------

* Issue - Improve `SSOCredentials` error handling when profile file does not exist (#2605)

3.121.5 (2021-10-29)
------------------

* Issue - bump minimum version of `aws-partitions` (#2603).

3.121.4 (2021-10-28)
------------------

* Issue - This version has been yanked. (#2603).

* Issue - use the `EndpointProvider` to lookup signing region and name.

3.121.3 (2021-10-20)
------------------

* Issue - Use endpointPrefix when looking up the `signing_region` from the `EndpointProvider`.

3.121.2 (2021-10-18)
------------------

* Issue - Fix an issue where Rest JSON services do not have a `Content-Type` header.

* Issue - Remove blank `Content-Type` header from Net::HTTP handler, and prevent a default from being set.

* Issue - Set `Content-Length` only for HTTP methods that take a body.

3.121.1 (2021-09-24)
------------------

* Issue - Fix error in finding union member for boolean shapes with `false` values.

3.121.0 (2021-09-02)
------------------

* Feature - Add support for S3 Multi-region access point configuration.

3.120.0 (2021-09-01)
------------------

* Feature - AWS SDK for Ruby no longer supports Ruby runtime versions 1.9, 2.0, 2.1, and 2.2.

3.119.1 (2021-08-20)
------------------

* Issue - Refactored `Aws::Json::Engine` to remove dead code and replaced usage of `JSON.load` with `JSON.parse`.

3.119.0 (2021-07-30)
------------------

* Feature - Support Document Types. Document types are used to carry open content. A document type value is serialized using the same format as its surroundings and requires no additional encoding or escaping.(#2523)

3.118.0 (2021-07-28)
------------------

* Feature - Add support for Tagged Unions using a "sealed" classes like approach where each union member has a corresponding subclass.

3.117.0 (2021-07-12)
------------------

* Feature - Support IPv6 endpoints for `Aws::InstanceProfileCredentials`. It supports two shared configuration options (`ec2_metadata_service_endpoint` & `ec2_metadata_service_endpoint_mode`), two ENV variables (`AWS_EC2_METADATA_SERVICE_ENDPOINT` & `AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE`), and two constructor options (`:endpoint` & `:endpoint_mode`).

* Feature - Support IPv6 endpoint for `Aws::EC2Metadata` client. It can be configured with `:endpoint` or `:endpoint_mode`.

3.116.0 (2021-07-07)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.115.0 (2021-06-23)
------------------

* Feature - Add support for Assume Role Chaining in profiles. (#2531)
* Issue - Fixed an issue with `Seahorse::Client::H2::Connection` for non-https endpoints. (#2542)

3.114.3 (2021-06-15)
------------------

* Issue - Fixed an issue with `Aws::PageableResponse` where it was modifying original params hash, causing frozen hashes to fail.

3.114.2 (2021-06-09)
------------------

* Issue - Fixed an issue with `Aws::PageableResponse` where intentionally nil tokens were not merged into the params for the next call.

3.114.1 (2021-06-02)
------------------

* Issue - Change XML Builder to not indent by default

3.114.0 (2021-04-13)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.113.1 (2021-03-29)
------------------

* Issue - Ensure end of line characters are correctly encoded in XML.

3.113.0 (2021-03-10)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

3.112.1 (2021-03-04)
------------------

* Issue - Include LICENSE, CHANGELOG, and VERSION files with this gem.

3.112.0 (2021-02-02)
------------------

* Feature - The `hostPrefix` trait will now be applied to any customer provided `:endpoint`. This bug fix is a minor behavioral change for clients using custom endpoints for `s3control`, `iotsitewise`, and `servicediscovery`. This behavior can be disabled by configuring `:disable_host_prefix_injection` to `true`.

3.111.2 (2021-01-19)
------------------

* Issue - Fix a loading issue with SSO and STS gem aliases using `require_relative` instead of `require`.

3.111.1 (2021-01-15)
------------------

* Issue - Fix an issue with `max_attempts` validation raising incorrectly.

3.111.0 (2021-01-11)
------------------

* Feature - Adds an IMDSv2 client as `Aws::EC2Metadata`.

3.110.0 (2020-12-03)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Issue - Support `aws-sdk-sts` alias gem.

* Issue - Retry when `Net:HTTPFatalError` is thrown by the `Net::HTTP` library. This can occur when proxy connections are configured. (#2439)

3.109.3 (2020-11-17)
------------------

* Issue - Use full namespace for SSO Client when creating `SSOCredentials`

3.109.2 (2020-11-04)
------------------

* Issue - Check for flattened on ref for lists when serializing.

3.109.1 (2020-10-05)
------------------

* Issue - For errors without a message, default to the error class. (#2388)

3.109.0 (2020-09-30)
------------------

* Feature - Add `Seahorse::Util.host_label?` to check strings for valid RFC-3986 host labels.
* Feature - Add `Aws::ARN#to_h`.

3.108.0 (2020-09-25)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.107.0 (2020-09-15)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Issue - Fix circular dependency of `aws-sdk-sso` and `aws-sdk-core` (#2405).

3.106.0 (2020-09-14)
------------------

* Feature - Support `AWS_CA_BUNDLE` ENV variable and `ca_bundle` shared configuration options. The `:ssl_ca_bundle` client option will override either of these options. (#1907)

3.105.0 (2020-08-25)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::SSO::Client with the latest API changes.

* Feature - Add `SSOCredentials`.  Moved functionality from `aws-sdk-sso` into core.

3.104.4 (2020-08-19)
------------------

* Issue - Use Aws::Json for parsing instead of JSON

3.104.3 (2020-07-23)
------------------

* Issue - Revert duplication of params.  Ensure code that relied on internal modification of parameters is not broken.

3.104.2 (2020-07-22)
------------------

* Issue - Validate IO like objects support read,rewind and size unless streaming. Fixes #2364

3.104.1 (2020-07-20)
------------------

* Issue - Duplicate params to ensure user provided params are not modified.  Fixes #2366

3.104.0 (2020-07-15)
------------------

* Feature - Add headers to the `ResponseTarget` callback.  A block passed as the response target on a streaming method will be called with the `chunk` and `headers`.
* Feature - Added the `RequestCallback` plugin which allows clients and methods to set `on_chunk_sent` to a `Proc` which will be called as each chunk of the request body is sent.

3.103.0 (2020-07-01)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.102.1 (2020-06-25)
------------------

* Issue - Set the `response_target` on the context when deleting it from the parameters.

3.102.0 (2020-06-24)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.101.0 (2020-06-23)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Added sensitive params to request and response Types instead of just on a large list.
* Feature - Provide an option `:filter_sensitive_params` for `Aws::Log::Formatter` to allow disabling of the sensitive param filter (#2312, #2105, #2082).

3.100.0 (2020-06-15)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.99.2 (2020-06-12)
------------------

* Issue - Don't retry streaming requests with blocks (#2311)

3.99.1 (2020-06-11)
------------------

* Issue - Republish after incorrect yank.

3.99.0 (2020-06-10)
------------------

* Issue - This version has been yanked. (#2327).
* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

* Feature - Support `httpChecksumRequired` on operations that require Content MD5 validation.
* Issue - Validate `:region` as a valid DNS host label.

3.98.0 (2020-06-05)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.97.1 (2020-06-01)
------------------

* Issue - Convert ENV['AWS_MAX_ATTEMPTS'] String value to Integer when set. (#2319)
* Issue - Handle unknown and unmodeled events from event streams by ignoring them and providing a new callback rather than raising an error.

3.97.0 (2020-05-28)
------------------
* Feature - Default endpoint_discovery to `true` for services with at least one operation that requires it.
* Feature - Updated Aws::STS::Client with the latest API changes.

3.96.1 (2020-05-18)
------------------

* Issue - Raise `ArgumentError` for XML services when required URI elements are not included.

3.96.0 (2020-05-15)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.95.0 (2020-05-07)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.94.1 (2020-05-04)
------------------

* Issue - When handling errors in XML responses, don't set a new error on the response if one is already set.

3.94.0 (2020-04-08)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Issue - Update dependency on aws-eventstream

3.93.0 (2020-04-06)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.92.0 (2020-03-20)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Issue - Change the default of `sts_regional_endpoints` from 'legacy' to 'regional'.

3.91.1 (2020-03-10)
------------------

* Issue - Rescue from `JSON::ParserError` when using `Oj.mimic_JSON`. (#2247)

3.91.0 (2020-03-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.
* Feature - Add `standard` and `adaptive` retry modes.

3.90.1 (2020-02-14)
------------------

* Issue - Perform a case-insensitive comparison when filtering sensitive parameters from logs
* Issue - Add passthrough of region from client to STS when using `assume_role_web_identity_credentials`.

3.90.0 (2020-02-12)
------------------

* Issue - Updated the list of parameters to filter when logging.
* Issue - Parse all values from shared credentials file when using `Aws.shared_config`.
* Issue - Honor explicit profile in client config when credentials from AWS_ environment variables are present.
* Issue - Fixed a bug where `Transfer-Encoding` could never be set to `chunked` in streaming operations because all body objects (`String`, `StringIO`) would respond to `#size`.

3.89.1 (2020-01-14)
------------------

* Issue - Fix erroneously reaped sessions from `Seahorse::Client::NetHttp::ConnectionPool` due to bad `last_used` time calculation
* Issue - Use monotonic clocks when reaping sessions in `Seahorse::Client::NetHttp::ConnectionPool`
* Issue - Fix "Conn close because of keep_alive_timeout" when reusing  `Seahorse::Client::NetHttp::ConnectionPool` sessions

3.89.0 (2020-01-13)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.88.0 (2020-01-10)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.87.0 (2020-01-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Issue - Reuse connections even if `http_wire_trace` is true.

3.86.0 (2019-12-13)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.85.1 (2019-12-11)
------------------

* Issue - Change default timeout to 1 and number of retries to 1 for `InstanceProfileCredentials`.

3.85.0 (2019-12-09)
------------------

* Feature - Add STS Presigner module with a method to generate a presigned EKS token.

* Issue - Fix issue for log formatters in clients where http_response_body does not respond to `rewind` when using a block.

3.84.0 (2019-12-04)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.83.0 (2019-12-03)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.82.0 (2019-11-25)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.81.0 (2019-11-22)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.80.0 (2019-11-20)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.79.0 (2019-11-19)
------------------

* Feature - Support EC2 IMDS updates.

3.78.0 (2019-11-15)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.77.0 (2019-11-13)
------------------

* Feature - Support `s3_us_east_1_regional_endpoint` from `SharedConfig`

3.76.0 (2019-11-07)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.75.0 (2019-11-06)
------------------

* Feature - Remove deprecated `access_key_id`, `secret_access_key`, and `session_token` methods in credential providers.

3.74.0 (2019-11-05)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.73.0 (2019-11-04)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.72.1 (2019-10-31)
------------------

* Issue - Fix `EndpointCache#key?` to be thread safe.

3.72.0 (2019-10-24)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Issue - Update minimum `aws-partition` gem dependency version

3.71.0 (2019-10-23)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Support enable STS regional endpoints by `sts_regional_endpoints: 'regional'`

3.70.0 (2019-10-22)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.69.1 (2019-10-18)
------------------

* Issue - Fix method redefinition warnings

3.69.0 (2019-10-17)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.68.1 (2019-10-02)
------------------

* Issue - Add final deprecation warnings to `access_key_id`, `secret_access_key`, and `session_token` in credential providers.

* Issue - Remove misleading IO documentation from `BlobShape` error output.

3.68.0 (2019-09-16)
------------------

* Feature - Support assuming a role with `:source_profile` from a profile that can be resolved from a `ProcessCredentials` provider.

3.67.0 (2019-09-09)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.66.0 (2019-09-04)
------------------

* Feature - Support CLI AWS_DEFAULT_PROFILE environment variable [Github Issue](https://github.com/aws/aws-sdk-ruby/issues/1452).

3.65.1 (2019-08-28)
------------------

* Issue - Auto refresh credentials for Route53 `ExpiredToken` errors.

3.65.0 (2019-08-27)
------------------

* Feature - Support assuming a role `:source_profile` profile with `AssumeRoleWebIdentityCredentials`.

3.64.0 (2019-08-20)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.63.0 (2019-08-15)
------------------

* Feature - Support passing AssumeRole `duration_seconds` from shared credentials/config file.

3.62.0 (2019-08-02)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.61.2 (2019-07-29)
------------------

* Issue - Add `Aws::STS::InvalidIdentityToken` and `Aws::Errors::NoSuchEndpointError` error for retry.

3.61.1 (2019-07-25)
------------------

* Issue - Fix default STS Client credential sourcing in `Aws::AssumeRoleWebIdentityCredentialsProvider`.

3.61.0 (2019-07-24)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.60.0 (2019-07-23)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Issue - Handle `EncodingError` when using Oj gem [Github Issue](https://github.com/aws/aws-sdk-ruby/issues/1831)

3.59.0 (2019-07-03)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.58.0 (2019-07-01)
------------------

* Feature - Support `Aws::AssumeRoleWebIdentityCredentials` provider

3.57.0 (2019-06-28)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.56.0 (2019-06-17)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Support `:client_side_monitoring_host` configuration for CSM

3.55.0 (2019-06-14)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.54.2 (2019-06-03)
------------------

* Issue - Mirgate Proc.new without a block usage #2058.

3.54.1 (2019-05-30)
------------------

* Issue - Improved exception messages in credential providers to exclude detailed parse errors that may contain sensitive information.

3.54.0 (2019-05-28)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.53.1 (2019-05-22)
------------------

* Issue - Support #to_hash for Struct with `:members` member #2053

3.53.0 (2019-05-21)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

* Feature - Adding support for modeled exceptions

3.52.1 (2019-05-15)
------------------

* Issue - Handle paginator stubs with expression #2040

3.52.0 (2019-05-14)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

* Feature - Support transfer encoding and `requiresLength` trait

3.51.0 (2019-05-10)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.50.0 (2019-05-06)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.49.0 (2019-04-30)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.48.6 (2019-04-26)
------------------

* Issue - Call RefreshingCredentials initialize method in ProcessCredentials to set mutex.

3.48.5 (2019-04-24)
------------------

* Issue - Add PriorRequestNotComplete to throttling errors.

3.48.4 (2019-04-18)
------------------

* Issue - Small memory retention reduction.

3.48.3 (2019-03-26)
------------------

* Issue - event header ":event-type" uses member name instead of shape name

3.48.2 (2019-03-20)
------------------

* Issue - Support signal events after request only [HTTP2]

3.48.1 (2019-03-19)
------------------

* Issue - Clean up unnecessary error output when 'http-2' gem is not present.

3.48.0 (2019-03-18)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Feature - Fix http-2 Dependency for Old Ruby Versions (Github Issue #1994)

3.47.0 (2019-03-14)
------------------

* Feature - Support HTTP/2 based AWS event stream operations

3.46.2 (2019-02-19)
------------------

* Issue - Update NetHttp Patches per Ruby version (Github Issue: #1979)

3.46.1 (2019-02-12)
------------------

* Issue - Fix the issue that APIG SDK doesn't have regional endpoint related plugins.

3.46.0 (2019-01-16)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.45.0 (2019-01-11)
------------------

* Feature - Improve Query protocol handling of empty responses, to ensure response is an instance of `Aws::EmptyStructure` rather than the class `Aws::EmptyStructure` itself.
* Issue - Plugin updates to support client-side monitoring.

3.44.2 (2019-01-04)
------------------

* Issue - Update to code paths and plugins for future SDK instrumentation and telemetry.

3.44.1 (2018-12-17)
------------------

* Issue - Update sensitive filtering logic to include `#to_s` calls of shapes.

3.44.0 (2018-12-07)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.43.0 (2018-12-04)
------------------

* Feature - Update user agent structure.

3.42.0 (2018-11-29)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.41.0 (2018-11-28)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.40.0 (2018-11-27)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.39.0 (2018-11-20)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

* Feature - Adding support for endpoint trait (host prefix) per operation, to disable this feature, set `:disable_host_prefix_injection` to `false` for the client.

3.38.0 (2018-11-12)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Feature - Adding `TransactionInProgressException` for throttling retry

3.37.0 (2018-11-08)
------------------

* Feature - Adding support for endpoint discovery per operation, to enable this feature, set `:endpoint_discovery` to `true` for the client. Note: only available for services with endpoint discovery support.

3.36.0 (2018-10-30)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.35.0 (2018-10-24)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.34.0 (2018-10-23)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Allow 429 response code to trigger throttle detection

3.33.0 (2018-10-22)
------------------

* Feature - Update to code paths and plugins for future SDK instrumentation and telemetry.

3.32.0 (2018-10-18)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.31.0 (2018-10-16)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.30.0 (2018-10-04)
------------------

* Feature - Adds to code paths and plugins for future SDK instrumentation and telemetry.

3.29.0 (2018-09-28)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.28.0 (2018-09-25)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.27.1 (2018-09-21)
------------------

* Issue - Fixes a bug in the `:response_target` plugin error callback. Under certain circumstances a special body object can be removed before its error callback is triggered, breaking retry logic.

3.27.0 (2018-09-06)
------------------

* Feature - Adds code paths and plugins for future SDK instrumentation and telemetry to aws-sdk-sts.

3.26.0 (2018-09-05)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Adds code paths and plugins for future SDK instrumentation and telemetry.

3.25.0 (2018-08-29)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Issue - Add `:exclude_presign` option for #api_requests at client stubbing to allow excluding non-sent request from presigned url (Github Issue #1866)

3.24.1 (2018-08-13)
------------------

* Issue - Update `ca-bundle.crt` file with newer root certificate authorities.

3.24.0 (2018-08-03)
------------------

* Feature - Extensible Credential Providers, allows you to declare an executable to be run that outputs the credentials as a JSON payload allowing you to develop custom credential providers and easily add them to the credential resolution chain, [Docs](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes)

3.23.0 (2018-07-31)
------------------

* Feature - Add Logged API Requests interface to stubbed clients

3.22.1 (2018-06-28)
------------------

* Issue - Performance enhancement to instance credential providers, to use a more precisely scoped Time parsing method for improved performance.

3.22.0 (2018-06-26)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Allows you to set custom paths to shared config and shared credential files via the `AWS_CONFIG_FILE` and `AWS_SHARED_CREDENTIALS_FILE` environment variables.

* Feature - Flexible retry strategies. Provides the `:retry_max_delay`, `:retry_base_delay`, and `:retry_jitter` options, which modify the default backoff strategy without the need to define a full retry lambda from scratch.

3.21.3 (2018-06-20)
------------------

* Issue - Fix to support URI encoded characters in http_proxy

3.21.2 (2018-05-22)
------------------

* Issue - Update `EventEmitter` to `Aws::EventEmitter` [Github Issue](https://github.com/aws/aws-sdk-ruby/issues/1791)

3.21.1 (2018-05-18)
------------------

* Issue - Remove `raw_stream` tracking, [Github Issue](https://github.com/aws/aws-sdk-ruby/issues/1786)

3.21.0 (2018-05-17)
------------------

* Feature - Support `vnd.amazon.event-stream` binary stream protocol over HTTP1.1

3.20.2 (2018-04-26)
------------------

* Issue - Avoiding Net::HTTP patching for Ruby 2.5

3.20.1 (2018-04-24)
------------------

* Issue - Fix parsing flattened XML shape from shape reference for S3 https://github.com/aws/aws-sdk-ruby/issues/1764

3.20.0 (2018-04-23)
------------------

* Feature - Aws::InstanceProfileCredentials - Add sending a User-Agent other than the default User-Agent in Ruby.  Adding the User-Agent `aws-sdk-ruby3/<version>` to allow protection against Server Side Request Forgery (SSRF) credential theft vectors by use of a metadata proxy.

3.19.0 (2018-04-04)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.18.1 (2018-03-29)
------------------

* Issue - Fix undefined method `each`/`next` for `Enumerable::Enumerator` when this class exists in the environment

3.18.0 (2018-03-28)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.17.1 (2018-03-20)
------------------

* Issue - Support timestamp shape in querystring

3.17.0 (2018-02-27)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Issue - Fix Ruby warnings: Shadowed local variables "parts" and "headers"

3.16.0 (2018-02-20)
------------------

* Feature - Aws::InstanceProfileCredentials - When the `AWS_EC2_METADATA_DISABLED` environment variable is present with the value `true` (not case sensitive), the `Aws::InstanceProfileCredentials` credential provider will not be used.

3.15.0 (2018-02-06)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.14.0 (2018-01-15)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.13.1 (2018-01-12)
------------------

* Issue - Fix Ruby 2.5 warnings.

3.13.0 (2017-12-21)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.12.0 (2017-12-20)
------------------

* Feature - Adds support for credential_source when assuming a role via shared configuration.

* Issue - Update APIGateway SDK user agent pattern

3.11.0 (2017-11-29)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.10.0 (2017-11-29)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.9.0 (2017-11-20)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.8.0 (2017-11-19)
------------------

* Feature - Add support for APIGateway protocol and custom service build.

3.7.0 (2017-11-07)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.6.1 (2017-11-07)
------------------

* Issue - Update empty struct stubbing shape

3.6.0 (2017-09-20)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.5.0 (2017-09-13)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.4.0 (2017-09-12)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.3.1 (2017-09-11)
------------------

* Issue - Fix core util deep copy issue #1603

3.3.0 (2017-09-07)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.2.1 (2017-09-06)
------------------

* Issue - Remove redundant version file.

3.2.0 (2017-08-31)
------------------

* Feature - Updated the list of parameters to filter when logging.

* Issue - Update `aws-sdk-core` gemspec metadata.

* Issue - Update `aws-sdk-core` gemspec metadata

3.1.0 (2017-08-30)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0 (2017-08-29)
------------------

3.0.0.rc20 (2017-08-14)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc19 (2017-07-31)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc18 (2017-07-24)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc17 (2017-07-12)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc16 (2017-07-06)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc15 (2017-07-06)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc14 (2017-06-29)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc13 (2017-06-26)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

* Issue - Aws::CredentialProviderChain - Fetching `AWS_PROFILE` environment variable before using `default` profile.

3.0.0.rc12 (2017-05-23)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Update throttling error pool of retry

* Feature - Update `User-Agent` format

3.0.0.rc11 (2017-05-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc10 (2017-05-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc9 (2017-05-05)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Added support for Ruby 2.4

* Issue - Revert 'cgi/util' change that breaks Ruby 2.4

3.0.0.rc8 (2017-04-21)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc7 (2017-03-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc6 (2017-03-08)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc5 (2017-03-07)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

3.0.0.rc4 (2017-03-07)
------------------

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc3 (2017-01-24)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc2 (2016-12-09)
------------------

* Feature - Updated Aws::STS::Client with the latest API changes.

* Feature - Updated the list of parameters to filter when logging.

3.0.0.rc1 (2016-12-05)
------------------

* Feature - Initial preview release of the `aws-sdk-core` gem.
