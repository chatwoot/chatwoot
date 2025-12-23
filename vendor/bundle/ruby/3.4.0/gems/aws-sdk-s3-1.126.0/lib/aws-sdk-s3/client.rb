# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

require 'seahorse/client/plugins/content_length.rb'
require 'aws-sdk-core/plugins/credentials_configuration.rb'
require 'aws-sdk-core/plugins/logging.rb'
require 'aws-sdk-core/plugins/param_converter.rb'
require 'aws-sdk-core/plugins/param_validator.rb'
require 'aws-sdk-core/plugins/user_agent.rb'
require 'aws-sdk-core/plugins/helpful_socket_errors.rb'
require 'aws-sdk-core/plugins/retry_errors.rb'
require 'aws-sdk-core/plugins/global_configuration.rb'
require 'aws-sdk-core/plugins/regional_endpoint.rb'
require 'aws-sdk-core/plugins/endpoint_discovery.rb'
require 'aws-sdk-core/plugins/endpoint_pattern.rb'
require 'aws-sdk-core/plugins/response_paging.rb'
require 'aws-sdk-core/plugins/stub_responses.rb'
require 'aws-sdk-core/plugins/idempotency_token.rb'
require 'aws-sdk-core/plugins/jsonvalue_converter.rb'
require 'aws-sdk-core/plugins/client_metrics_plugin.rb'
require 'aws-sdk-core/plugins/client_metrics_send_plugin.rb'
require 'aws-sdk-core/plugins/transfer_encoding.rb'
require 'aws-sdk-core/plugins/http_checksum.rb'
require 'aws-sdk-core/plugins/checksum_algorithm.rb'
require 'aws-sdk-core/plugins/defaults_mode.rb'
require 'aws-sdk-core/plugins/recursion_detection.rb'
require 'aws-sdk-core/plugins/sign.rb'
require 'aws-sdk-core/plugins/protocols/rest_xml.rb'
require 'aws-sdk-s3/plugins/accelerate.rb'
require 'aws-sdk-s3/plugins/arn.rb'
require 'aws-sdk-s3/plugins/bucket_dns.rb'
require 'aws-sdk-s3/plugins/bucket_name_restrictions.rb'
require 'aws-sdk-s3/plugins/dualstack.rb'
require 'aws-sdk-s3/plugins/expect_100_continue.rb'
require 'aws-sdk-s3/plugins/get_bucket_location_fix.rb'
require 'aws-sdk-s3/plugins/http_200_errors.rb'
require 'aws-sdk-s3/plugins/iad_regional_endpoint.rb'
require 'aws-sdk-s3/plugins/location_constraint.rb'
require 'aws-sdk-s3/plugins/md5s.rb'
require 'aws-sdk-s3/plugins/redirects.rb'
require 'aws-sdk-s3/plugins/s3_host_id.rb'
require 'aws-sdk-s3/plugins/s3_signer.rb'
require 'aws-sdk-s3/plugins/sse_cpk.rb'
require 'aws-sdk-s3/plugins/streaming_retry.rb'
require 'aws-sdk-s3/plugins/url_encoded_keys.rb'
require 'aws-sdk-s3/plugins/skip_whole_multipart_get_checksums.rb'
require 'aws-sdk-core/plugins/event_stream_configuration.rb'

Aws::Plugins::GlobalConfiguration.add_identifier(:s3)

module Aws::S3
  # An API client for S3.  To construct a client, you need to configure a `:region` and `:credentials`.
  #
  #     client = Aws::S3::Client.new(
  #       region: region_name,
  #       credentials: credentials,
  #       # ...
  #     )
  #
  # For details on configuring region and credentials see
  # the [developer guide](/sdk-for-ruby/v3/developer-guide/setup-config.html).
  #
  # See {#initialize} for a full list of supported configuration options.
  class Client < Seahorse::Client::Base

    include Aws::ClientStubs

    @identifier = :s3

    set_api(ClientApi::API)

    add_plugin(Seahorse::Client::Plugins::ContentLength)
    add_plugin(Aws::Plugins::CredentialsConfiguration)
    add_plugin(Aws::Plugins::Logging)
    add_plugin(Aws::Plugins::ParamConverter)
    add_plugin(Aws::Plugins::ParamValidator)
    add_plugin(Aws::Plugins::UserAgent)
    add_plugin(Aws::Plugins::HelpfulSocketErrors)
    add_plugin(Aws::Plugins::RetryErrors)
    add_plugin(Aws::Plugins::GlobalConfiguration)
    add_plugin(Aws::Plugins::RegionalEndpoint)
    add_plugin(Aws::Plugins::EndpointDiscovery)
    add_plugin(Aws::Plugins::EndpointPattern)
    add_plugin(Aws::Plugins::ResponsePaging)
    add_plugin(Aws::Plugins::StubResponses)
    add_plugin(Aws::Plugins::IdempotencyToken)
    add_plugin(Aws::Plugins::JsonvalueConverter)
    add_plugin(Aws::Plugins::ClientMetricsPlugin)
    add_plugin(Aws::Plugins::ClientMetricsSendPlugin)
    add_plugin(Aws::Plugins::TransferEncoding)
    add_plugin(Aws::Plugins::HttpChecksum)
    add_plugin(Aws::Plugins::ChecksumAlgorithm)
    add_plugin(Aws::Plugins::DefaultsMode)
    add_plugin(Aws::Plugins::RecursionDetection)
    add_plugin(Aws::Plugins::Sign)
    add_plugin(Aws::Plugins::Protocols::RestXml)
    add_plugin(Aws::S3::Plugins::Accelerate)
    add_plugin(Aws::S3::Plugins::ARN)
    add_plugin(Aws::S3::Plugins::BucketDns)
    add_plugin(Aws::S3::Plugins::BucketNameRestrictions)
    add_plugin(Aws::S3::Plugins::Dualstack)
    add_plugin(Aws::S3::Plugins::Expect100Continue)
    add_plugin(Aws::S3::Plugins::GetBucketLocationFix)
    add_plugin(Aws::S3::Plugins::Http200Errors)
    add_plugin(Aws::S3::Plugins::IADRegionalEndpoint)
    add_plugin(Aws::S3::Plugins::LocationConstraint)
    add_plugin(Aws::S3::Plugins::Md5s)
    add_plugin(Aws::S3::Plugins::Redirects)
    add_plugin(Aws::S3::Plugins::S3HostId)
    add_plugin(Aws::S3::Plugins::S3Signer)
    add_plugin(Aws::S3::Plugins::SseCpk)
    add_plugin(Aws::S3::Plugins::StreamingRetry)
    add_plugin(Aws::S3::Plugins::UrlEncodedKeys)
    add_plugin(Aws::S3::Plugins::SkipWholeMultipartGetChecksums)
    add_plugin(Aws::Plugins::EventStreamConfiguration)
    add_plugin(Aws::S3::Plugins::Endpoints)

    # @overload initialize(options)
    #   @param [Hash] options
    #   @option options [required, Aws::CredentialProvider] :credentials
    #     Your AWS credentials. This can be an instance of any one of the
    #     following classes:
    #
    #     * `Aws::Credentials` - Used for configuring static, non-refreshing
    #       credentials.
    #
    #     * `Aws::SharedCredentials` - Used for loading static credentials from a
    #       shared file, such as `~/.aws/config`.
    #
    #     * `Aws::AssumeRoleCredentials` - Used when you need to assume a role.
    #
    #     * `Aws::AssumeRoleWebIdentityCredentials` - Used when you need to
    #       assume a role after providing credentials via the web.
    #
    #     * `Aws::SSOCredentials` - Used for loading credentials from AWS SSO using an
    #       access token generated from `aws login`.
    #
    #     * `Aws::ProcessCredentials` - Used for loading credentials from a
    #       process that outputs to stdout.
    #
    #     * `Aws::InstanceProfileCredentials` - Used for loading credentials
    #       from an EC2 IMDS on an EC2 instance.
    #
    #     * `Aws::ECSCredentials` - Used for loading credentials from
    #       instances running in ECS.
    #
    #     * `Aws::CognitoIdentityCredentials` - Used for loading credentials
    #       from the Cognito Identity service.
    #
    #     When `:credentials` are not configured directly, the following
    #     locations will be searched for credentials:
    #
    #     * `Aws.config[:credentials]`
    #     * The `:access_key_id`, `:secret_access_key`, and `:session_token` options.
    #     * ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #     * EC2/ECS IMDS instance profile - When used by default, the timeouts
    #       are very aggressive. Construct and pass an instance of
    #       `Aws::InstanceProfileCredentails` or `Aws::ECSCredentials` to
    #       enable retries and extended timeouts. Instance profile credential
    #       fetching can be disabled by setting ENV['AWS_EC2_METADATA_DISABLED']
    #       to true.
    #
    #   @option options [required, String] :region
    #     The AWS region to connect to.  The configured `:region` is
    #     used to determine the service `:endpoint`. When not passed,
    #     a default `:region` is searched for in the following locations:
    #
    #     * `Aws.config[:region]`
    #     * `ENV['AWS_REGION']`
    #     * `ENV['AMAZON_REGION']`
    #     * `ENV['AWS_DEFAULT_REGION']`
    #     * `~/.aws/credentials`
    #     * `~/.aws/config`
    #
    #   @option options [String] :access_key_id
    #
    #   @option options [Boolean] :active_endpoint_cache (false)
    #     When set to `true`, a thread polling for endpoints will be running in
    #     the background every 60 secs (default). Defaults to `false`.
    #
    #   @option options [Boolean] :adaptive_retry_wait_to_fill (true)
    #     Used only in `adaptive` retry mode.  When true, the request will sleep
    #     until there is sufficent client side capacity to retry the request.
    #     When false, the request will raise a `RetryCapacityNotAvailableError` and will
    #     not retry instead of sleeping.
    #
    #   @option options [Boolean] :client_side_monitoring (false)
    #     When `true`, client-side metrics will be collected for all API requests from
    #     this client.
    #
    #   @option options [String] :client_side_monitoring_client_id ("")
    #     Allows you to provide an identifier for this client which will be attached to
    #     all generated client side metrics. Defaults to an empty string.
    #
    #   @option options [String] :client_side_monitoring_host ("127.0.0.1")
    #     Allows you to specify the DNS hostname or IPv4 or IPv6 address that the client
    #     side monitoring agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Integer] :client_side_monitoring_port (31000)
    #     Required for publishing client metrics. The port that the client side monitoring
    #     agent is running on, where client metrics will be published via UDP.
    #
    #   @option options [Aws::ClientSideMonitoring::Publisher] :client_side_monitoring_publisher (Aws::ClientSideMonitoring::Publisher)
    #     Allows you to provide a custom client-side monitoring publisher class. By default,
    #     will use the Client Side Monitoring Agent Publisher.
    #
    #   @option options [Boolean] :compute_checksums (true)
    #     When `true` a MD5 checksum will be computed and sent in the Content Md5
    #     header for :put_object and :upload_part. When `false`, MD5 checksums
    #     will not be computed for these operations. Checksums are still computed
    #     for operations requiring them. Checksum errors returned by Amazon S3 are
    #     automatically retried up to `:retry_limit` times.
    #
    #   @option options [Boolean] :convert_params (true)
    #     When `true`, an attempt is made to coerce request parameters into
    #     the required types.
    #
    #   @option options [Boolean] :correct_clock_skew (true)
    #     Used only in `standard` and adaptive retry modes. Specifies whether to apply
    #     a clock skew correction and retry requests with skewed client clocks.
    #
    #   @option options [String] :defaults_mode ("legacy")
    #     See {Aws::DefaultsModeConfiguration} for a list of the
    #     accepted modes and the configuration defaults that are included.
    #
    #   @option options [Boolean] :disable_host_prefix_injection (false)
    #     Set to true to disable SDK automatically adding host prefix
    #     to default service endpoint when available.
    #
    #   @option options [String] :endpoint
    #     The client endpoint is normally constructed from the `:region`
    #     option. You should only configure an `:endpoint` when connecting
    #     to test or custom endpoints. This should be a valid HTTP(S) URI.
    #
    #   @option options [Integer] :endpoint_cache_max_entries (1000)
    #     Used for the maximum size limit of the LRU cache storing endpoints data
    #     for endpoint discovery enabled operations. Defaults to 1000.
    #
    #   @option options [Integer] :endpoint_cache_max_threads (10)
    #     Used for the maximum threads in use for polling endpoints to be cached, defaults to 10.
    #
    #   @option options [Integer] :endpoint_cache_poll_interval (60)
    #     When :endpoint_discovery and :active_endpoint_cache is enabled,
    #     Use this option to config the time interval in seconds for making
    #     requests fetching endpoints information. Defaults to 60 sec.
    #
    #   @option options [Boolean] :endpoint_discovery (false)
    #     When set to `true`, endpoint discovery will be enabled for operations when available.
    #
    #   @option options [Proc] :event_stream_handler
    #     When an EventStream or Proc object is provided, it will be used as callback for each chunk of event stream response received along the way.
    #
    #   @option options [Boolean] :follow_redirects (true)
    #     When `true`, this client will follow 307 redirects returned
    #     by Amazon S3.
    #
    #   @option options [Boolean] :force_path_style (false)
    #     When set to `true`, the bucket name is always left in the
    #     request URI and never moved to the host as a sub-domain.
    #
    #   @option options [Proc] :input_event_stream_handler
    #     When an EventStream or Proc object is provided, it can be used for sending events for the event stream.
    #
    #   @option options [Aws::Log::Formatter] :log_formatter (Aws::Log::Formatter.default)
    #     The log formatter.
    #
    #   @option options [Symbol] :log_level (:info)
    #     The log level to send messages to the `:logger` at.
    #
    #   @option options [Logger] :logger
    #     The Logger instance to send log messages to.  If this option
    #     is not set, logging will be disabled.
    #
    #   @option options [Integer] :max_attempts (3)
    #     An integer representing the maximum number attempts that will be made for
    #     a single request, including the initial attempt.  For example,
    #     setting this value to 5 will result in a request being retried up to
    #     4 times. Used in `standard` and `adaptive` retry modes.
    #
    #   @option options [Proc] :output_event_stream_handler
    #     When an EventStream or Proc object is provided, it will be used as callback for each chunk of event stream response received along the way.
    #
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file
    #     at HOME/.aws/credentials.  When not specified, 'default' is used.
    #
    #   @option options [Boolean] :require_https_for_sse_cpk (true)
    #     When `true`, the endpoint **must** be HTTPS for all operations
    #     where server-side-encryption is used with customer-provided keys.
    #     This should only be disabled for local testing.
    #
    #   @option options [Proc] :retry_backoff
    #     A proc or lambda used for backoff. Defaults to 2**retries * retry_base_delay.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Float] :retry_base_delay (0.3)
    #     The base delay in seconds used by the default backoff function. This option
    #     is only used in the `legacy` retry mode.
    #
    #   @option options [Symbol] :retry_jitter (:none)
    #     A delay randomiser function used by the default backoff function.
    #     Some predefined functions can be referenced by name - :none, :equal, :full,
    #     otherwise a Proc that takes and returns a number. This option is only used
    #     in the `legacy` retry mode.
    #
    #     @see https://www.awsarchitectureblog.com/2015/03/backoff.html
    #
    #   @option options [Integer] :retry_limit (3)
    #     The maximum number of times to retry failed requests.  Only
    #     ~ 500 level server errors and certain ~ 400 level client errors
    #     are retried.  Generally, these are throttling errors, data
    #     checksum errors, networking errors, timeout errors, auth errors,
    #     endpoint discovery, and errors from expired credentials.
    #     This option is only used in the `legacy` retry mode.
    #
    #   @option options [Integer] :retry_max_delay (0)
    #     The maximum number of seconds to delay between retries (0 for no limit)
    #     used by the default backoff function. This option is only used in the
    #     `legacy` retry mode.
    #
    #   @option options [String] :retry_mode ("legacy")
    #     Specifies which retry algorithm to use. Values are:
    #
    #     * `legacy` - The pre-existing retry behavior.  This is default value if
    #       no retry mode is provided.
    #
    #     * `standard` - A standardized set of retry rules across the AWS SDKs.
    #       This includes support for retry quotas, which limit the number of
    #       unsuccessful retries a client can make.
    #
    #     * `adaptive` - An experimental retry mode that includes all the
    #       functionality of `standard` mode along with automatic client side
    #       throttling.  This is a provisional mode that may change behavior
    #       in the future.
    #
    #
    #   @option options [Boolean] :s3_disable_multiregion_access_points (false)
    #     When set to `false` this will option will raise errors when multi-region
    #     access point ARNs are used.  Multi-region access points can potentially
    #     result in cross region requests.
    #
    #   @option options [String] :s3_us_east_1_regional_endpoint ("legacy")
    #     Pass in `regional` to enable the `us-east-1` regional endpoint.
    #     Defaults to `legacy` mode which uses the global endpoint.
    #
    #   @option options [Boolean] :s3_use_arn_region (true)
    #     For S3 ARNs passed into the `:bucket` parameter, this option will
    #     use the region in the ARN, allowing for cross-region requests to
    #     be made. Set to `false` to use the client's region instead.
    #
    #   @option options [String] :sdk_ua_app_id
    #     A unique and opaque application ID that is appended to the
    #     User-Agent header as app/<sdk_ua_app_id>. It should have a
    #     maximum length of 50.
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [Boolean] :stub_responses (false)
    #     Causes the client to return stubbed responses. By default
    #     fake responses are generated and returned. You can specify
    #     the response data to return or errors to raise by calling
    #     {ClientStubs#stub_responses}. See {ClientStubs} for more information.
    #
    #     ** Please note ** When response stubbing is enabled, no HTTP
    #     requests are made, and retries are disabled.
    #
    #   @option options [Aws::TokenProvider] :token_provider
    #     A Bearer Token Provider. This can be an instance of any one of the
    #     following classes:
    #
    #     * `Aws::StaticTokenProvider` - Used for configuring static, non-refreshing
    #       tokens.
    #
    #     * `Aws::SSOTokenProvider` - Used for loading tokens from AWS SSO using an
    #       access token generated from `aws login`.
    #
    #     When `:token_provider` is not configured directly, the `Aws::TokenProviderChain`
    #     will be used to search for tokens configured for your profile in shared configuration files.
    #
    #   @option options [Boolean] :use_accelerate_endpoint (false)
    #     When set to `true`, accelerated bucket endpoints will be used
    #     for all object operations. You must first enable accelerate for
    #     each bucket. [Go here for more information](http://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html).
    #
    #   @option options [Boolean] :use_dualstack_endpoint
    #     When set to `true`, dualstack enabled endpoints (with `.aws` TLD)
    #     will be used if available.
    #
    #   @option options [Boolean] :use_fips_endpoint
    #     When set to `true`, fips compatible endpoints will be used if available.
    #     When a `fips` region is used, the region is normalized and this config
    #     is set to `true`.
    #
    #   @option options [Boolean] :validate_params (true)
    #     When `true`, request parameters are validated before
    #     sending the request.
    #
    #   @option options [Aws::S3::EndpointProvider] :endpoint_provider
    #     The endpoint provider used to resolve endpoints. Any object that responds to `#resolve_endpoint(parameters)` where `parameters` is a Struct similar to `Aws::S3::EndpointParameters`
    #
    #   @option options [URI::HTTP,String] :http_proxy A proxy to send
    #     requests through.  Formatted like 'http://proxy.com:123'.
    #
    #   @option options [Float] :http_open_timeout (15) The number of
    #     seconds to wait when opening a HTTP session before raising a
    #     `Timeout::Error`.
    #
    #   @option options [Float] :http_read_timeout (60) The default
    #     number of seconds to wait for response data.  This value can
    #     safely be set per-request on the session.
    #
    #   @option options [Float] :http_idle_timeout (5) The number of
    #     seconds a connection is allowed to sit idle before it is
    #     considered stale.  Stale connections are closed and removed
    #     from the pool before making a request.
    #
    #   @option options [Float] :http_continue_timeout (1) The number of
    #     seconds to wait for a 100-continue response before sending the
    #     request body.  This option has no effect unless the request has
    #     "Expect" header set to "100-continue".  Defaults to `nil` which
    #     disables this behaviour.  This value can safely be set per
    #     request on the session.
    #
    #   @option options [Float] :ssl_timeout (nil) Sets the SSL timeout
    #     in seconds.
    #
    #   @option options [Boolean] :http_wire_trace (false) When `true`,
    #     HTTP debug output will be sent to the `:logger`.
    #
    #   @option options [Boolean] :ssl_verify_peer (true) When `true`,
    #     SSL peer certificates are verified when establishing a
    #     connection.
    #
    #   @option options [String] :ssl_ca_bundle Full path to the SSL
    #     certificate authority bundle file that should be used when
    #     verifying peer certificates.  If you do not pass
    #     `:ssl_ca_bundle` or `:ssl_ca_directory` the the system default
    #     will be used if available.
    #
    #   @option options [String] :ssl_ca_directory Full path of the
    #     directory that contains the unbundled SSL certificate
    #     authority files for verifying peer certificates.  If you do
    #     not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the
    #     system default will be used if available.
    #
    def initialize(*args)
      super
    end

    # @!group API Operations

    # This action aborts a multipart upload. After a multipart upload is
    # aborted, no additional parts can be uploaded using that upload ID. The
    # storage consumed by any previously uploaded parts will be freed.
    # However, if any part uploads are currently in progress, those part
    # uploads might or might not succeed. As a result, it might be necessary
    # to abort a given multipart upload multiple times in order to
    # completely free all storage consumed by all parts.
    #
    # To verify that all parts have been removed, so you don't get charged
    # for the part storage, you should call the [ListParts][1] action and
    # ensure that the parts list is empty.
    #
    # For information about permissions required to use the multipart
    # upload, see [Multipart Upload and Permissions][2].
    #
    # The following operations are related to `AbortMultipartUpload`:
    #
    # * [CreateMultipartUpload][3]
    #
    # * [UploadPart][4]
    #
    # * [CompleteMultipartUpload][5]
    #
    # * [ListParts][1]
    #
    # * [ListMultipartUploads][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [required, String] :bucket
    #   The bucket name to which the upload was taking place.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Key of the object for which the multipart upload was initiated.
    #
    # @option params [required, String] :upload_id
    #   Upload ID that identifies the multipart upload.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::AbortMultipartUploadOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AbortMultipartUploadOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To abort a multipart upload
    #
    #   # The following example aborts a multipart upload.
    #
    #   resp = client.abort_multipart_upload({
    #     bucket: "examplebucket", 
    #     key: "bigobject", 
    #     upload_id: "xadcOB_7YPBOJuoFiQ9cz4P3Pe6FIZwO4f7wN93uHsNBEw97pl5eNwzExg0LAT2dUN91cOmrEQHDsP3WA60CEg--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.abort_multipart_upload({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     upload_id: "MultipartUploadId", # required
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/AbortMultipartUpload AWS API Documentation
    #
    # @overload abort_multipart_upload(params = {})
    # @param [Hash] params ({})
    def abort_multipart_upload(params = {}, options = {})
      req = build_request(:abort_multipart_upload, params)
      req.send_request(options)
    end

    # Completes a multipart upload by assembling previously uploaded parts.
    #
    # You first initiate the multipart upload and then upload all parts
    # using the [UploadPart][1] operation. After successfully uploading all
    # relevant parts of an upload, you call this action to complete the
    # upload. Upon receiving this request, Amazon S3 concatenates all the
    # parts in ascending order by part number to create a new object. In the
    # Complete Multipart Upload request, you must provide the parts list.
    # You must ensure that the parts list is complete. This action
    # concatenates the parts that you provide in the list. For each part in
    # the list, you must provide the part number and the `ETag` value,
    # returned after that part was uploaded.
    #
    # Processing of a Complete Multipart Upload request could take several
    # minutes to complete. After Amazon S3 begins processing the request, it
    # sends an HTTP response header that specifies a 200 OK response. While
    # processing is in progress, Amazon S3 periodically sends white space
    # characters to keep the connection from timing out. A request could
    # fail after the initial 200 OK response has been sent. This means that
    # a `200 OK` response can contain either a success or an error. If you
    # call the S3 API directly, make sure to design your application to
    # parse the contents of the response and handle it appropriately. If you
    # use Amazon Web Services SDKs, SDKs handle this condition. The SDKs
    # detect the embedded error and apply error handling per your
    # configuration settings (including automatically retrying the request
    # as appropriate). If the condition persists, the SDKs throws an
    # exception (or, for the SDKs that don't use exceptions, they return
    # the error).
    #
    # Note that if `CompleteMultipartUpload` fails, applications should be
    # prepared to retry the failed requests. For more information, see
    # [Amazon S3 Error Best Practices][2].
    #
    # You cannot use `Content-Type: application/x-www-form-urlencoded` with
    # Complete Multipart Upload requests. Also, if you do not provide a
    # `Content-Type` header, `CompleteMultipartUpload` returns a 200 OK
    # response.
    #
    # For more information about multipart uploads, see [Uploading Objects
    # Using Multipart Upload][3].
    #
    # For information about permissions required to use the multipart upload
    # API, see [Multipart Upload and Permissions][4].
    #
    # `CompleteMultipartUpload` has the following special errors:
    #
    # * Error code: `EntityTooSmall`
    #
    #   * Description: Your proposed upload is smaller than the minimum
    #     allowed object size. Each part must be at least 5 MB in size,
    #     except the last part.
    #
    #   * 400 Bad Request
    #
    # * Error code: `InvalidPart`
    #
    #   * Description: One or more of the specified parts could not be
    #     found. The part might not have been uploaded, or the specified
    #     entity tag might not have matched the part's entity tag.
    #
    #   * 400 Bad Request
    #
    # * Error code: `InvalidPartOrder`
    #
    #   * Description: The list of parts was not in ascending order. The
    #     parts list must be specified in order by part number.
    #
    #   * 400 Bad Request
    #
    # * Error code: `NoSuchUpload`
    #
    #   * Description: The specified multipart upload does not exist. The
    #     upload ID might be invalid, or the multipart upload might have
    #     been aborted or completed.
    #
    #   * 404 Not Found
    #
    # The following operations are related to `CompleteMultipartUpload`:
    #
    # * [CreateMultipartUpload][5]
    #
    # * [UploadPart][1]
    #
    # * [AbortMultipartUpload][6]
    #
    # * [ListParts][7]
    #
    # * [ListMultipartUploads][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ErrorBestPractices.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [required, String] :bucket
    #   Name of the bucket to which the multipart upload was initiated.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Object key for which the multipart upload was initiated.
    #
    # @option params [Types::CompletedMultipartUpload] :multipart_upload
    #   The container for the multipart upload request information.
    #
    # @option params [required, String] :upload_id
    #   ID for the initiated multipart upload.
    #
    # @option params [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32 checksum of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32C checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 160-bit SHA-1 digest of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 256-bit SHA-256 digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the object.
    #   This parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This parameter
    #   is needed only when the object was created using a checksum algorithm.
    #   For more information, see [Protecting data using SSE-C keys][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a checksum
    #   algorithm. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @return [Types::CompleteMultipartUploadOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CompleteMultipartUploadOutput#location #location} => String
    #   * {Types::CompleteMultipartUploadOutput#bucket #bucket} => String
    #   * {Types::CompleteMultipartUploadOutput#key #key} => String
    #   * {Types::CompleteMultipartUploadOutput#expiration #expiration} => String
    #   * {Types::CompleteMultipartUploadOutput#etag #etag} => String
    #   * {Types::CompleteMultipartUploadOutput#checksum_crc32 #checksum_crc32} => String
    #   * {Types::CompleteMultipartUploadOutput#checksum_crc32c #checksum_crc32c} => String
    #   * {Types::CompleteMultipartUploadOutput#checksum_sha1 #checksum_sha1} => String
    #   * {Types::CompleteMultipartUploadOutput#checksum_sha256 #checksum_sha256} => String
    #   * {Types::CompleteMultipartUploadOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::CompleteMultipartUploadOutput#version_id #version_id} => String
    #   * {Types::CompleteMultipartUploadOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::CompleteMultipartUploadOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::CompleteMultipartUploadOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To complete multipart upload
    #
    #   # The following example completes a multipart upload.
    #
    #   resp = client.complete_multipart_upload({
    #     bucket: "examplebucket", 
    #     key: "bigobject", 
    #     multipart_upload: {
    #       parts: [
    #         {
    #           etag: "\"d8c2eafd90c266e19ab9dcacc479f8af\"", 
    #           part_number: 1, 
    #         }, 
    #         {
    #           etag: "\"d8c2eafd90c266e19ab9dcacc479f8af\"", 
    #           part_number: 2, 
    #         }, 
    #       ], 
    #     }, 
    #     upload_id: "7YPBOJuoFiQ9cz4P3Pe6FIZwO4f7wN93uHsNBEw97pl5eNwzExg0LAT2dUN91cOmrEQHDsP3WA60CEg--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     bucket: "acexamplebucket", 
    #     etag: "\"4d9031c7644d8081c2829f4ea23c55f7-2\"", 
    #     key: "bigobject", 
    #     location: "https://examplebucket.s3.<Region>.amazonaws.com/bigobject", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.complete_multipart_upload({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     multipart_upload: {
    #       parts: [
    #         {
    #           etag: "ETag",
    #           checksum_crc32: "ChecksumCRC32",
    #           checksum_crc32c: "ChecksumCRC32C",
    #           checksum_sha1: "ChecksumSHA1",
    #           checksum_sha256: "ChecksumSHA256",
    #           part_number: 1,
    #         },
    #       ],
    #     },
    #     upload_id: "MultipartUploadId", # required
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #   })
    #
    # @example Response structure
    #
    #   resp.location #=> String
    #   resp.bucket #=> String
    #   resp.key #=> String
    #   resp.expiration #=> String
    #   resp.etag #=> String
    #   resp.checksum_crc32 #=> String
    #   resp.checksum_crc32c #=> String
    #   resp.checksum_sha1 #=> String
    #   resp.checksum_sha256 #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.version_id #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CompleteMultipartUpload AWS API Documentation
    #
    # @overload complete_multipart_upload(params = {})
    # @param [Hash] params ({})
    def complete_multipart_upload(params = {}, options = {})
      req = build_request(:complete_multipart_upload, params)
      req.send_request(options)
    end

    # Creates a copy of an object that is already stored in Amazon S3.
    #
    # <note markdown="1"> You can store individual objects of up to 5 TB in Amazon S3. You
    # create a copy of your object up to 5 GB in size in a single atomic
    # action using this API. However, to copy an object greater than 5 GB,
    # you must use the multipart upload Upload Part - Copy (UploadPartCopy)
    # API. For more information, see [Copy Object Using the REST Multipart
    # Upload API][1].
    #
    #  </note>
    #
    # All copy requests must be authenticated. Additionally, you must have
    # *read* access to the source object and *write* access to the
    # destination bucket. For more information, see [REST
    # Authentication][2]. Both the Region that you want to copy the object
    # from and the Region that you want to copy the object to must be
    # enabled for your account.
    #
    # A copy request might return an error when Amazon S3 receives the copy
    # request or while Amazon S3 is copying the files. If the error occurs
    # before the copy action starts, you receive a standard Amazon S3 error.
    # If the error occurs during the copy operation, the error response is
    # embedded in the `200 OK` response. This means that a `200 OK` response
    # can contain either a success or an error. If you call the S3 API
    # directly, make sure to design your application to parse the contents
    # of the response and handle it appropriately. If you use Amazon Web
    # Services SDKs, SDKs handle this condition. The SDKs detect the
    # embedded error and apply error handling per your configuration
    # settings (including automatically retrying the request as
    # appropriate). If the condition persists, the SDKs throws an exception
    # (or, for the SDKs that don't use exceptions, they return the error).
    #
    # If the copy is successful, you receive a response with information
    # about the copied object.
    #
    # <note markdown="1"> If the request is an HTTP 1.1 request, the response is chunk encoded.
    # If it were not, it would not contain the content-length, and you would
    # need to read the entire body.
    #
    #  </note>
    #
    # The copy request charge is based on the storage class and Region that
    # you specify for the destination object. For pricing information, see
    # [Amazon S3 pricing][3].
    #
    # Amazon S3 transfer acceleration does not support cross-Region copies.
    # If you request a cross-Region copy using a transfer acceleration
    # endpoint, you get a 400 `Bad Request` error. For more information, see
    # [Transfer Acceleration][4].
    #
    # Metadata
    #
    # : When copying an object, you can preserve all metadata (the default)
    #   or specify new metadata. However, the access control list (ACL) is
    #   not preserved and is set to private for the user making the request.
    #   To override the default ACL setting, specify a new ACL when
    #   generating a copy request. For more information, see [Using
    #   ACLs][5].
    #
    #   To specify whether you want the object metadata copied from the
    #   source object or replaced with metadata provided in the request, you
    #   can optionally add the `x-amz-metadata-directive` header. When you
    #   grant permissions, you can use the `s3:x-amz-metadata-directive`
    #   condition key to enforce certain metadata behavior when objects are
    #   uploaded. For more information, see [Specifying Conditions in a
    #   Policy][6] in the *Amazon S3 User Guide*. For a complete list of
    #   Amazon S3-specific condition keys, see [Actions, Resources, and
    #   Condition Keys for Amazon S3][7].
    #
    #   <note markdown="1"> `x-amz-website-redirect-location` is unique to each object and must
    #   be specified in the request headers to copy the value.
    #
    #    </note>
    #
    # x-amz-copy-source-if Headers
    #
    # : To only copy an object under certain conditions, such as whether the
    #   `Etag` matches or whether the object was modified before or after a
    #   specified date, use the following request parameters:
    #
    #   * `x-amz-copy-source-if-match`
    #
    #   * `x-amz-copy-source-if-none-match`
    #
    #   * `x-amz-copy-source-if-unmodified-since`
    #
    #   * `x-amz-copy-source-if-modified-since`
    #
    #   If both the `x-amz-copy-source-if-match` and
    #   `x-amz-copy-source-if-unmodified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns `200 OK` and
    #   copies the data:
    #
    #   * `x-amz-copy-source-if-match` condition evaluates to true
    #
    #   * `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #     false
    #
    #   If both the `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request and evaluate as follows, Amazon S3 returns the `412
    #   Precondition Failed` response code:
    #
    #   * `x-amz-copy-source-if-none-match` condition evaluates to false
    #
    #   * `x-amz-copy-source-if-modified-since` condition evaluates to true
    #
    #   <note markdown="1"> All headers with the `x-amz-` prefix, including `x-amz-copy-source`,
    #   must be signed.
    #
    #    </note>
    #
    # Server-side encryption
    #
    # : Amazon S3 automatically encrypts all new objects that are copied to
    #   an S3 bucket. When copying an object, if you don't specify
    #   encryption information in your copy request, the encryption setting
    #   of the target object is set to the default encryption configuration
    #   of the destination bucket. By default, all buckets have a base level
    #   of encryption configuration that uses server-side encryption with
    #   Amazon S3 managed keys (SSE-S3). If the destination bucket has a
    #   default encryption configuration that uses server-side encryption
    #   with Key Management Service (KMS) keys (SSE-KMS), dual-layer
    #   server-side encryption with Amazon Web Services KMS keys (DSSE-KMS),
    #   or server-side encryption with customer-provided encryption keys
    #   (SSE-C), Amazon S3 uses the corresponding KMS key, or a
    #   customer-provided key to encrypt the target object copy.
    #
    #   When you perform a `CopyObject` operation, if you want to use a
    #   different type of encryption setting for the target object, you can
    #   use other appropriate encryption-related headers to encrypt the
    #   target object with a KMS key, an Amazon S3 managed key, or a
    #   customer-provided key. With server-side encryption, Amazon S3
    #   encrypts your data as it writes your data to disks in its data
    #   centers and decrypts the data when you access it. If the encryption
    #   setting in your request is different from the default encryption
    #   configuration of the destination bucket, the encryption setting in
    #   your request takes precedence. If the source object for the copy is
    #   stored in Amazon S3 using SSE-C, you must provide the necessary
    #   encryption information in your request so that Amazon S3 can decrypt
    #   the object for copying. For more information about server-side
    #   encryption, see [Using Server-Side Encryption][8].
    #
    #   If a target object uses SSE-KMS, you can enable an S3 Bucket Key for
    #   the object. For more information, see [Amazon S3 Bucket Keys][9] in
    #   the *Amazon S3 User Guide*.
    #
    # Access Control List (ACL)-Specific Request Headers
    #
    # : When copying an object, you can optionally use headers to grant
    #   ACL-based permissions. By default, all objects are private. Only the
    #   owner has full access control. When adding a new object, you can
    #   grant permissions to individual Amazon Web Services accounts or to
    #   predefined groups that are defined by Amazon S3. These permissions
    #   are then added to the ACL on the object. For more information, see
    #   [Access Control List (ACL) Overview][10] and [Managing ACLs Using
    #   the REST API][11].
    #
    #   If the bucket that you're copying objects to uses the bucket owner
    #   enforced setting for S3 Object Ownership, ACLs are disabled and no
    #   longer affect permissions. Buckets that use this setting only accept
    #   `PUT` requests that don't specify an ACL or `PUT` requests that
    #   specify bucket owner full control ACLs, such as the
    #   `bucket-owner-full-control` canned ACL or an equivalent form of this
    #   ACL expressed in the XML format.
    #
    #   For more information, see [ Controlling ownership of objects and
    #   disabling ACLs][12] in the *Amazon S3 User Guide*.
    #
    #   <note markdown="1"> If your bucket uses the bucket owner enforced setting for Object
    #   Ownership, all objects written to the bucket by any account will be
    #   owned by the bucket owner.
    #
    #    </note>
    #
    # Checksums
    #
    # : When copying an object, if it has a checksum, that checksum will be
    #   copied to the new object by default. When you copy the object over,
    #   you can optionally specify a different checksum algorithm to use
    #   with the `x-amz-checksum-algorithm` header.
    #
    # Storage Class Options
    #
    # : You can use the `CopyObject` action to change the storage class of
    #   an object that is already stored in Amazon S3 by using the
    #   `StorageClass` parameter. For more information, see [Storage
    #   Classes][13] in the *Amazon S3 User Guide*.
    #
    #   If the source object's storage class is GLACIER, you must restore a
    #   copy of this object before you can use it as a source object for the
    #   copy operation. For more information, see [RestoreObject][14]. For
    #   more information, see [Copying Objects][15].
    #
    # Versioning
    #
    # : By default, `x-amz-copy-source` header identifies the current
    #   version of an object to copy. If the current version is a delete
    #   marker, Amazon S3 behaves as if the object was deleted. To copy a
    #   different version, use the `versionId` subresource.
    #
    #   If you enable versioning on the target bucket, Amazon S3 generates a
    #   unique version ID for the object being copied. This version ID is
    #   different from the version ID of the source object. Amazon S3
    #   returns the version ID of the copied object in the
    #   `x-amz-version-id` response header in the response.
    #
    #   If you do not enable versioning or suspend it on the target bucket,
    #   the version ID that Amazon S3 generates is always null.
    #
    # The following operations are related to `CopyObject`:
    #
    # * [PutObject][16]
    #
    # * [GetObject][17]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjctsUsingRESTMPUapi.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    # [3]: http://aws.amazon.com/s3/pricing/
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/amazon-s3-policy-keys.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/dev/list_amazons3.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-rest-api.html
    # [12]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [13]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    # [14]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    # [15]: https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjectsExamples.html
    # [16]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [17]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :bucket
    #   The name of the destination bucket.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :cache_control
    #   Specifies caching behavior along the request/reply chain.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :content_disposition
    #   Specifies presentational information for the object.
    #
    # @option params [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field.
    #
    # @option params [String] :content_language
    #   The language the content is in.
    #
    # @option params [String] :content_type
    #   A standard MIME type describing the format of the object data.
    #
    # @option params [required, String] :copy_source
    #   Specifies the source object for the copy operation. You specify the
    #   value in one of two formats, depending on whether you want to access
    #   the source object through an [access point][1]:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and the key of the source object, separated by
    #     a slash (/). For example, to copy the object `reports/january.pdf`
    #     from the bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be
    #     URL-encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through access
    #     point `my-access-point` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf`.
    #     The value must be URL encoded.
    #
    #     <note markdown="1"> Amazon S3 supports copy operations using access points only when the
    #     source and destination buckets are in the same Amazon Web Services
    #     Region.
    #
    #      </note>
    #
    #     Alternatively, for objects accessed through Amazon S3 on Outposts,
    #     specify the ARN of the object as accessed in the format
    #     `arn:aws:s3-outposts:<Region>:<account-id>:outpost/<outpost-id>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     outpost `my-outpost` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/object/reports/january.pdf`.
    #     The value must be URL-encoded.
    #
    #   To copy a specific version of an object, append
    #   `?versionId=<version-id>` to the value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
    #
    # @option params [String] :copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified tag.
    #
    # @option params [Time,DateTime,Date,Integer,String] :copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #
    # @option params [String] :copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #
    # @option params [Time,DateTime,Date,Integer,String] :copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #
    # @option params [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable.
    #
    # @option params [String] :grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :key
    #   The key of the destination object.
    #
    # @option params [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    #
    # @option params [String] :metadata_directive
    #   Specifies whether the metadata is copied from the source object or
    #   replaced with metadata provided in the request.
    #
    # @option params [String] :tagging_directive
    #   Specifies whether the object tag-set are copied from the source object
    #   or replaced with tag-set provided in the request.
    #
    # @option params [String] :server_side_encryption
    #   The server-side encryption algorithm used when storing this object in
    #   Amazon S3 (for example, `AES256`, `aws:kms`, `aws:kms:dsse`).
    #
    # @option params [String] :storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can specify
    #   a different Storage Class. Amazon S3 on Outposts only uses the
    #   OUTPOSTS Storage Class. For more information, see [Storage Classes][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #
    # @option params [String] :website_redirect_location
    #   If the bucket is configured as a website, redirects requests for this
    #   object to another object in the same bucket or to an external URL.
    #   Amazon S3 stores the value of this header in the object metadata. This
    #   value is unique to each object and is not copied when using the
    #   `x-amz-metadata-directive` header. Instead, you may opt to provide
    #   this header in combination with the directive.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :ssekms_key_id
    #   Specifies the KMS key ID to use for object encryption. All GET and PUT
    #   requests for an object protected by KMS will fail if they're not made
    #   via SSL or using SigV4. For information about configuring any of the
    #   officially supported Amazon Web Services SDKs and Amazon Web Services
    #   CLI, see [Specifying the Signature Version in Request
    #   Authentication][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
    #
    # @option params [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #
    # @option params [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). Setting this header to `true` causes Amazon S3
    #   to use an S3 Bucket Key for object encryption with SSE-KMS.
    #
    #   Specifying this header with a COPY action doesn’t affect bucket-level
    #   settings for S3 Bucket Key.
    #
    # @option params [String] :copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object (for
    #   example, AES256).
    #
    # @option params [String] :copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use to
    #   decrypt the source object. The encryption key provided in this header
    #   must be one that was used when the source object was created.
    #
    # @option params [String] :copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :tagging
    #   The tag-set for the object destination object this value must be used
    #   in conjunction with the `TaggingDirective`. The tag-set must be
    #   encoded as URL Query parameters.
    #
    # @option params [String] :object_lock_mode
    #   The Object Lock mode that you want to apply to the copied object.
    #
    # @option params [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   The date and time when you want the copied object's Object Lock to
    #   expire.
    #
    # @option params [String] :object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the copied object.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected destination bucket owner. If the
    #   destination bucket is owned by a different account, the request fails
    #   with the HTTP status code `403 Forbidden` (access denied).
    #
    # @option params [String] :expected_source_bucket_owner
    #   The account ID of the expected source bucket owner. If the source
    #   bucket is owned by a different account, the request fails with the
    #   HTTP status code `403 Forbidden` (access denied).
    #
    # @return [Types::CopyObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CopyObjectOutput#copy_object_result #copy_object_result} => Types::CopyObjectResult
    #   * {Types::CopyObjectOutput#expiration #expiration} => String
    #   * {Types::CopyObjectOutput#copy_source_version_id #copy_source_version_id} => String
    #   * {Types::CopyObjectOutput#version_id #version_id} => String
    #   * {Types::CopyObjectOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::CopyObjectOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::CopyObjectOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::CopyObjectOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::CopyObjectOutput#ssekms_encryption_context #ssekms_encryption_context} => String
    #   * {Types::CopyObjectOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::CopyObjectOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To copy an object
    #
    #   # The following example copies an object from one bucket to another.
    #
    #   resp = client.copy_object({
    #     bucket: "destinationbucket", 
    #     copy_source: "/sourcebucket/HappyFacejpg", 
    #     key: "HappyFaceCopyjpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     copy_object_result: {
    #       etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #       last_modified: Time.parse("2016-12-15T17:38:53.000Z"), 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.copy_object({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     bucket: "BucketName", # required
    #     cache_control: "CacheControl",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_type: "ContentType",
    #     copy_source: "CopySource", # required
    #     copy_source_if_match: "CopySourceIfMatch",
    #     copy_source_if_modified_since: Time.now,
    #     copy_source_if_none_match: "CopySourceIfNoneMatch",
    #     copy_source_if_unmodified_since: Time.now,
    #     expires: Time.now,
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     key: "ObjectKey", # required
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     metadata_directive: "COPY", # accepts COPY, REPLACE
    #     tagging_directive: "COPY", # accepts COPY, REPLACE
    #     server_side_encryption: "AES256", # accepts AES256, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     copy_source_sse_customer_algorithm: "CopySourceSSECustomerAlgorithm",
    #     copy_source_sse_customer_key: "CopySourceSSECustomerKey",
    #     copy_source_sse_customer_key_md5: "CopySourceSSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #     expected_source_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.copy_object_result.etag #=> String
    #   resp.copy_object_result.last_modified #=> Time
    #   resp.copy_object_result.checksum_crc32 #=> String
    #   resp.copy_object_result.checksum_crc32c #=> String
    #   resp.copy_object_result.checksum_sha1 #=> String
    #   resp.copy_object_result.checksum_sha256 #=> String
    #   resp.expiration #=> String
    #   resp.copy_source_version_id #=> String
    #   resp.version_id #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.ssekms_encryption_context #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CopyObject AWS API Documentation
    #
    # @overload copy_object(params = {})
    # @param [Hash] params ({})
    def copy_object(params = {}, options = {})
      req = build_request(:copy_object, params)
      req.send_request(options)
    end

    # Creates a new S3 bucket. To create a bucket, you must register with
    # Amazon S3 and have a valid Amazon Web Services Access Key ID to
    # authenticate requests. Anonymous requests are never allowed to create
    # buckets. By creating the bucket, you become the bucket owner.
    #
    # Not every string is an acceptable bucket name. For information about
    # bucket naming restrictions, see [Bucket naming rules][1].
    #
    # If you want to create an Amazon S3 on Outposts bucket, see [Create
    # Bucket][2].
    #
    # By default, the bucket is created in the US East (N. Virginia) Region.
    # You can optionally specify a Region in the request body. You might
    # choose a Region to optimize latency, minimize costs, or address
    # regulatory requirements. For example, if you reside in Europe, you
    # will probably find it advantageous to create buckets in the Europe
    # (Ireland) Region. For more information, see [Accessing a bucket][3].
    #
    # <note markdown="1"> If you send your create bucket request to the `s3.amazonaws.com`
    # endpoint, the request goes to the `us-east-1` Region. Accordingly, the
    # signature calculations in Signature Version 4 must use `us-east-1` as
    # the Region, even if the location constraint in the request specifies
    # another Region where the bucket is to be created. If you create a
    # bucket in a Region other than US East (N. Virginia), your application
    # must be able to handle 307 redirect. For more information, see
    # [Virtual hosting of buckets][4].
    #
    #  </note>
    #
    # Permissions
    #
    # : In addition to `s3:CreateBucket`, the following permissions are
    #   required when your `CreateBucket` request includes specific headers:
    #
    #   * **Access control lists (ACLs)** - If your `CreateBucket` request
    #     specifies access control list (ACL) permissions and the ACL is
    #     public-read, public-read-write, authenticated-read, or if you
    #     specify access permissions explicitly through any other ACL, both
    #     `s3:CreateBucket` and `s3:PutBucketAcl` permissions are needed. If
    #     the ACL for the `CreateBucket` request is private or if the
    #     request doesn't specify any ACLs, only `s3:CreateBucket`
    #     permission is needed.
    #
    #   * **Object Lock** - If `ObjectLockEnabledForBucket` is set to true
    #     in your `CreateBucket` request,
    #     `s3:PutBucketObjectLockConfiguration` and `s3:PutBucketVersioning`
    #     permissions are required.
    #
    #   * **S3 Object Ownership** - If your `CreateBucket` request includes
    #     the `x-amz-object-ownership` header, then the
    #     `s3:PutBucketOwnershipControls` permission is required. By
    #     default, `ObjectOwnership` is set to `BucketOWnerEnforced` and
    #     ACLs are disabled. We recommend keeping ACLs disabled, except in
    #     uncommon use cases where you must control access for each object
    #     individually. If you want to change the `ObjectOwnership` setting,
    #     you can use the `x-amz-object-ownership` header in your
    #     `CreateBucket` request to set the `ObjectOwnership` setting of
    #     your choice. For more information about S3 Object Ownership, see
    #     [Controlling object ownership ][5] in the *Amazon S3 User Guide*.
    #
    #   * **S3 Block Public Access** - If your specific use case requires
    #     granting public access to your S3 resources, you can disable Block
    #     Public Access. You can create a new bucket with Block Public
    #     Access enabled, then separately call the [
    #     `DeletePublicAccessBlock` ][6] API. To use this operation, you
    #     must have the `s3:PutBucketPublicAccessBlock` permission. By
    #     default, all Block Public Access settings are enabled for new
    #     buckets. To avoid inadvertent exposure of your resources, we
    #     recommend keeping the S3 Block Public Access settings enabled. For
    #     more information about S3 Block Public Access, see [Blocking
    #     public access to your Amazon S3 storage ][5] in the *Amazon S3
    #     User Guide*.
    #
    # If your `CreateBucket` request sets `BucketOwnerEnforced` for Amazon
    # S3 Object Ownership and specifies a bucket ACL that provides access to
    # an external Amazon Web Services account, your request fails with a
    # `400` error and returns the `InvalidBucketAcLWithObjectOwnership`
    # error code. For more information, see [Setting Object Ownership on an
    # existing bucket ][7] in the *Amazon S3 User Guide*.
    #
    # The following operations are related to `CreateBucket`:
    #
    # * [PutObject][8]
    #
    # * [DeleteBucket][9]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_control_CreateBucket.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-ownership-existing-bucket.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the bucket.
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to create.
    #
    # @option params [Types::CreateBucketConfiguration] :create_bucket_configuration
    #   The configuration information for the bucket.
    #
    # @option params [String] :grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions on
    #   the bucket.
    #
    # @option params [String] :grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    # @option params [String] :grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    # @option params [Boolean] :object_lock_enabled_for_bucket
    #   Specifies whether you want S3 Object Lock to be enabled for the new
    #   bucket.
    #
    # @option params [String] :object_ownership
    #   The container element for object ownership for a bucket's ownership
    #   controls.
    #
    #   BucketOwnerPreferred - Objects uploaded to the bucket change ownership
    #   to the bucket owner if the objects are uploaded with the
    #   `bucket-owner-full-control` canned ACL.
    #
    #   ObjectWriter - The uploading account will own the object if the object
    #   is uploaded with the `bucket-owner-full-control` canned ACL.
    #
    #   BucketOwnerEnforced - Access control lists (ACLs) are disabled and no
    #   longer affect permissions. The bucket owner automatically owns and has
    #   full control over every object in the bucket. The bucket only accepts
    #   PUT requests that don't specify an ACL or bucket owner full control
    #   ACLs, such as the `bucket-owner-full-control` canned ACL or an
    #   equivalent form of this ACL expressed in the XML format.
    #
    # @return [Types::CreateBucketOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateBucketOutput#location #location} => String
    #
    #
    # @example Example: To create a bucket 
    #
    #   # The following example creates a bucket.
    #
    #   resp = client.create_bucket({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     location: "/examplebucket", 
    #   }
    #
    # @example Example: To create a bucket in a specific region
    #
    #   # The following example creates a bucket. The request specifies an AWS region where to create the bucket.
    #
    #   resp = client.create_bucket({
    #     bucket: "examplebucket", 
    #     create_bucket_configuration: {
    #       location_constraint: "eu-west-1", 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     location: "http://examplebucket.<Region>.s3.amazonaws.com/", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_bucket({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #     bucket: "BucketName", # required
    #     create_bucket_configuration: {
    #       location_constraint: "af-south-1", # accepts af-south-1, ap-east-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1, ap-southeast-1, ap-southeast-2, ap-southeast-3, ca-central-1, cn-north-1, cn-northwest-1, EU, eu-central-1, eu-north-1, eu-south-1, eu-west-1, eu-west-2, eu-west-3, me-south-1, sa-east-1, us-east-2, us-gov-east-1, us-gov-west-1, us-west-1, us-west-2
    #     },
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write: "GrantWrite",
    #     grant_write_acp: "GrantWriteACP",
    #     object_lock_enabled_for_bucket: false,
    #     object_ownership: "BucketOwnerPreferred", # accepts BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
    #   })
    #
    # @example Response structure
    #
    #   resp.location #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateBucket AWS API Documentation
    #
    # @overload create_bucket(params = {})
    # @param [Hash] params ({})
    def create_bucket(params = {}, options = {})
      req = build_request(:create_bucket, params)
      req.send_request(options)
    end

    # This action initiates a multipart upload and returns an upload ID.
    # This upload ID is used to associate all of the parts in the specific
    # multipart upload. You specify this upload ID in each of your
    # subsequent upload part requests (see [UploadPart][1]). You also
    # include this upload ID in the final request to either complete or
    # abort the multipart upload request.
    #
    # For more information about multipart uploads, see [Multipart Upload
    # Overview][2].
    #
    # If you have configured a lifecycle rule to abort incomplete multipart
    # uploads, the upload must complete within the number of days specified
    # in the bucket lifecycle configuration. Otherwise, the incomplete
    # multipart upload becomes eligible for an abort action and Amazon S3
    # aborts the multipart upload. For more information, see [Aborting
    # Incomplete Multipart Uploads Using a Bucket Lifecycle
    # Configuration][3].
    #
    # For information about the permissions required to use the multipart
    # upload API, see [Multipart Upload and Permissions][4].
    #
    # For request signing, multipart upload is just a series of regular
    # requests. You initiate a multipart upload, send one or more requests
    # to upload parts, and then complete the multipart upload process. You
    # sign each request individually. There is nothing special about signing
    # multipart upload requests. For more information about signing, see
    # [Authenticating Requests (Amazon Web Services Signature Version
    # 4)][5].
    #
    # <note markdown="1"> After you initiate a multipart upload and upload one or more parts, to
    # stop being charged for storing the uploaded parts, you must either
    # complete or abort the multipart upload. Amazon S3 frees up the space
    # used to store the parts and stop charging you for storing them only
    # after you either complete or abort a multipart upload.
    #
    #  </note>
    #
    # Server-side encryption is for data encryption at rest. Amazon S3
    # encrypts your data as it writes it to disks in its data centers and
    # decrypts it when you access it. Amazon S3 automatically encrypts all
    # new objects that are uploaded to an S3 bucket. When doing a multipart
    # upload, if you don't specify encryption information in your request,
    # the encryption setting of the uploaded parts is set to the default
    # encryption configuration of the destination bucket. By default, all
    # buckets have a base level of encryption configuration that uses
    # server-side encryption with Amazon S3 managed keys (SSE-S3). If the
    # destination bucket has a default encryption configuration that uses
    # server-side encryption with an Key Management Service (KMS) key
    # (SSE-KMS), or a customer-provided encryption key (SSE-C), Amazon S3
    # uses the corresponding KMS key, or a customer-provided key to encrypt
    # the uploaded parts. When you perform a CreateMultipartUpload
    # operation, if you want to use a different type of encryption setting
    # for the uploaded parts, you can request that Amazon S3 encrypts the
    # object with a KMS key, an Amazon S3 managed key, or a
    # customer-provided key. If the encryption setting in your request is
    # different from the default encryption configuration of the destination
    # bucket, the encryption setting in your request takes precedence. If
    # you choose to provide your own encryption key, the request headers you
    # provide in [UploadPart][1] and [UploadPartCopy][6] requests must match
    # the headers you used in the request to initiate the upload by using
    # `CreateMultipartUpload`. You can request that Amazon S3 save the
    # uploaded parts encrypted with server-side encryption with an Amazon S3
    # managed key (SSE-S3), an Key Management Service (KMS) key (SSE-KMS),
    # or a customer-provided encryption key (SSE-C).
    #
    # To perform a multipart upload with encryption by using an Amazon Web
    # Services KMS key, the requester must have permission to the
    # `kms:Decrypt` and `kms:GenerateDataKey*` actions on the key. These
    # permissions are required because Amazon S3 must decrypt and read data
    # from the encrypted file parts before it completes the multipart
    # upload. For more information, see [Multipart upload API and
    # permissions][7] and [Protecting data using server-side encryption with
    # Amazon Web Services KMS][8] in the *Amazon S3 User Guide*.
    #
    # If your Identity and Access Management (IAM) user or role is in the
    # same Amazon Web Services account as the KMS key, then you must have
    # these permissions on the key policy. If your IAM user or role belongs
    # to a different account than the key, then you must have the
    # permissions on both the key policy and your IAM user or role.
    #
    # For more information, see [Protecting Data Using Server-Side
    # Encryption][9].
    #
    # Access Permissions
    #
    # : When copying an object, you can optionally specify the accounts or
    #   groups that should be granted specific permissions on the new
    #   object. There are two ways to grant the permissions using the
    #   request headers:
    #
    #   * Specify a canned ACL with the `x-amz-acl` request header. For more
    #     information, see [Canned ACL][10].
    #
    #   * Specify access permissions explicitly with the `x-amz-grant-read`,
    #     `x-amz-grant-read-acp`, `x-amz-grant-write-acp`, and
    #     `x-amz-grant-full-control` headers. These parameters map to the
    #     set of permissions that Amazon S3 supports in an ACL. For more
    #     information, see [Access Control List (ACL) Overview][11].
    #
    #   You can use either a canned ACL or specify access permissions
    #   explicitly. You cannot do both.
    #
    # Server-Side- Encryption-Specific Request Headers
    #
    # : Amazon S3 encrypts data by using server-side encryption with an
    #   Amazon S3 managed key (SSE-S3) by default. Server-side encryption is
    #   for data encryption at rest. Amazon S3 encrypts your data as it
    #   writes it to disks in its data centers and decrypts it when you
    #   access it. You can request that Amazon S3 encrypts data at rest by
    #   using server-side encryption with other key options. The option you
    #   use depends on whether you want to use KMS keys (SSE-KMS) or provide
    #   your own encryption keys (SSE-C).
    #
    #   * Use KMS keys (SSE-KMS) that include the Amazon Web Services
    #     managed key (`aws/s3`) and KMS customer managed keys stored in Key
    #     Management Service (KMS) – If you want Amazon Web Services to
    #     manage the keys used to encrypt data, specify the following
    #     headers in the request.
    #
    #     * `x-amz-server-side-encryption`
    #
    #     * `x-amz-server-side-encryption-aws-kms-key-id`
    #
    #     * `x-amz-server-side-encryption-context`
    #
    #     <note markdown="1"> If you specify `x-amz-server-side-encryption:aws:kms`, but don't
    #     provide `x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3
    #     uses the Amazon Web Services managed key (`aws/s3` key) in KMS to
    #     protect the data.
    #
    #      </note>
    #
    #     All `GET` and `PUT` requests for an object protected by KMS fail
    #     if you don't make them by using Secure Sockets Layer (SSL),
    #     Transport Layer Security (TLS), or Signature Version 4.
    #
    #     For more information about server-side encryption with KMS keys
    #     (SSE-KMS), see [Protecting Data Using Server-Side Encryption with
    #     KMS keys][8].
    #
    #   * Use customer-provided encryption keys (SSE-C) – If you want to
    #     manage your own encryption keys, provide all the following headers
    #     in the request.
    #
    #     * `x-amz-server-side-encryption-customer-algorithm`
    #
    #     * `x-amz-server-side-encryption-customer-key`
    #
    #     * `x-amz-server-side-encryption-customer-key-MD5`
    #
    #     For more information about server-side encryption with
    #     customer-provided encryption keys (SSE-C), see [ Protecting data
    #     using server-side encryption with customer-provided encryption
    #     keys (SSE-C)][12].
    #
    # Access-Control-List (ACL)-Specific Request Headers
    #
    # : You also can use the following access control–related headers with
    #   this operation. By default, all objects are private. Only the owner
    #   has full access control. When adding a new object, you can grant
    #   permissions to individual Amazon Web Services accounts or to
    #   predefined groups defined by Amazon S3. These permissions are then
    #   added to the access control list (ACL) on the object. For more
    #   information, see [Using ACLs][13]. With this operation, you can
    #   grant access permissions using one of the following two methods:
    #
    #   * Specify a canned ACL (`x-amz-acl`) — Amazon S3 supports a set of
    #     predefined ACLs, known as *canned ACLs*. Each canned ACL has a
    #     predefined set of grantees and permissions. For more information,
    #     see [Canned ACL][10].
    #
    #   * Specify access permissions explicitly — To explicitly grant access
    #     permissions to specific Amazon Web Services accounts or groups,
    #     use the following headers. Each header maps to specific
    #     permissions that Amazon S3 supports in an ACL. For more
    #     information, see [Access Control List (ACL) Overview][11]. In the
    #     header, you specify a list of grantees who get the specific
    #     permission. To grant permissions explicitly, use:
    #
    #     * `x-amz-grant-read`
    #
    #     * `x-amz-grant-write`
    #
    #     * `x-amz-grant-read-acp`
    #
    #     * `x-amz-grant-write-acp`
    #
    #     * `x-amz-grant-full-control`
    #
    #     You specify each grantee as a type=value pair, where the type is
    #     one of the following:
    #
    #     * `id` – if the value specified is the canonical user ID of an
    #       Amazon Web Services account
    #
    #     * `uri` – if you are granting permissions to a predefined group
    #
    #     * `emailAddress` – if the value specified is the email address of
    #       an Amazon Web Services account
    #
    #       <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #       the following Amazon Web Services Regions:
    #
    #        * US East (N. Virginia)
    #
    #       * US West (N. California)
    #
    #       * US West (Oregon)
    #
    #       * Asia Pacific (Singapore)
    #
    #       * Asia Pacific (Sydney)
    #
    #       * Asia Pacific (Tokyo)
    #
    #       * Europe (Ireland)
    #
    #       * South America (São Paulo)
    #
    #        For a list of all the Amazon S3 supported Regions and endpoints,
    #       see [Regions and Endpoints][14] in the Amazon Web Services
    #       General Reference.
    #
    #        </note>
    #
    #     For example, the following `x-amz-grant-read` header grants the
    #     Amazon Web Services accounts identified by account IDs permissions
    #     to read object data and its metadata:
    #
    #     `x-amz-grant-read: id="11112222333", id="444455556666" `
    #
    # The following operations are related to `CreateMultipartUpload`:
    #
    # * [UploadPart][1]
    #
    # * [CompleteMultipartUpload][15]
    #
    # * [AbortMultipartUpload][16]
    #
    # * [ListParts][17]
    #
    # * [ListMultipartUploads][18]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html#mpuAndPermissions
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    # [12]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html
    # [13]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    # [14]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # [15]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [16]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    # [17]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [18]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to which to initiate the upload
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :cache_control
    #   Specifies caching behavior along the request/reply chain.
    #
    # @option params [String] :content_disposition
    #   Specifies presentational information for the object.
    #
    # @option params [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field.
    #
    # @option params [String] :content_language
    #   The language the content is in.
    #
    # @option params [String] :content_type
    #   A standard MIME type describing the format of the object data.
    #
    # @option params [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable.
    #
    # @option params [String] :grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :key
    #   Object key for which the multipart upload is to be initiated.
    #
    # @option params [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    #
    # @option params [String] :server_side_encryption
    #   The server-side encryption algorithm used when storing this object in
    #   Amazon S3 (for example, `AES256`, `aws:kms`).
    #
    # @option params [String] :storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can specify
    #   a different Storage Class. Amazon S3 on Outposts only uses the
    #   OUTPOSTS Storage Class. For more information, see [Storage Classes][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #
    # @option params [String] :website_redirect_location
    #   If the bucket is configured as a website, redirects requests for this
    #   object to another object in the same bucket or to an external URL.
    #   Amazon S3 stores the value of this header in the object metadata.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :ssekms_key_id
    #   Specifies the ID of the symmetric encryption customer managed key to
    #   use for object encryption. All GET and PUT requests for an object
    #   protected by KMS will fail if they're not made via SSL or using
    #   SigV4. For information about configuring any of the officially
    #   supported Amazon Web Services SDKs and Amazon Web Services CLI, see
    #   [Specifying the Signature Version in Request Authentication][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
    #
    # @option params [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs.
    #
    # @option params [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). Setting this header to `true` causes Amazon S3
    #   to use an S3 Bucket Key for object encryption with SSE-KMS.
    #
    #   Specifying this header with an object action doesn’t affect
    #   bucket-level settings for S3 Bucket Key.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters.
    #
    # @option params [String] :object_lock_mode
    #   Specifies the Object Lock mode that you want to apply to the uploaded
    #   object.
    #
    # @option params [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   Specifies the date and time when you want the Object Lock to expire.
    #
    # @option params [String] :object_lock_legal_hold_status
    #   Specifies whether you want to apply a legal hold to the uploaded
    #   object.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm you want Amazon S3 to use to create the
    #   checksum for the object. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @return [Types::CreateMultipartUploadOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::CreateMultipartUploadOutput#abort_date #abort_date} => Time
    #   * {Types::CreateMultipartUploadOutput#abort_rule_id #abort_rule_id} => String
    #   * {Types::CreateMultipartUploadOutput#bucket #bucket} => String
    #   * {Types::CreateMultipartUploadOutput#key #key} => String
    #   * {Types::CreateMultipartUploadOutput#upload_id #upload_id} => String
    #   * {Types::CreateMultipartUploadOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::CreateMultipartUploadOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::CreateMultipartUploadOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::CreateMultipartUploadOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::CreateMultipartUploadOutput#ssekms_encryption_context #ssekms_encryption_context} => String
    #   * {Types::CreateMultipartUploadOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::CreateMultipartUploadOutput#request_charged #request_charged} => String
    #   * {Types::CreateMultipartUploadOutput#checksum_algorithm #checksum_algorithm} => String
    #
    #
    # @example Example: To initiate a multipart upload
    #
    #   # The following example initiates a multipart upload.
    #
    #   resp = client.create_multipart_upload({
    #     bucket: "examplebucket", 
    #     key: "largeobject", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     bucket: "examplebucket", 
    #     key: "largeobject", 
    #     upload_id: "ibZBv_75gd9r8lH_gqXatLdxMVpAlj6ZQjEs.OwyF3953YdwbcQnMA2BLGn8Lx12fQNICtMw5KyteFeHw.Sjng--", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.create_multipart_upload({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     bucket: "BucketName", # required
    #     cache_control: "CacheControl",
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_type: "ContentType",
    #     expires: Time.now,
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     key: "ObjectKey", # required
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     server_side_encryption: "AES256", # accepts AES256, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #   })
    #
    # @example Response structure
    #
    #   resp.abort_date #=> Time
    #   resp.abort_rule_id #=> String
    #   resp.bucket #=> String
    #   resp.key #=> String
    #   resp.upload_id #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.ssekms_encryption_context #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #   resp.checksum_algorithm #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/CreateMultipartUpload AWS API Documentation
    #
    # @overload create_multipart_upload(params = {})
    # @param [Hash] params ({})
    def create_multipart_upload(params = {}, options = {})
      req = build_request(:create_multipart_upload, params)
      req.send_request(options)
    end

    # Deletes the S3 bucket. All objects (including all object versions and
    # delete markers) in the bucket must be deleted before the bucket itself
    # can be deleted.
    #
    # The following operations are related to `DeleteBucket`:
    #
    # * [CreateBucket][1]
    #
    # * [DeleteObject][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    #
    # @option params [required, String] :bucket
    #   Specifies the bucket being deleted.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete a bucket
    #
    #   # The following example deletes the specified bucket.
    #
    #   resp = client.delete_bucket({
    #     bucket: "forrandall2", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucket AWS API Documentation
    #
    # @overload delete_bucket(params = {})
    # @param [Hash] params ({})
    def delete_bucket(params = {}, options = {})
      req = build_request(:delete_bucket, params)
      req.send_request(options)
    end

    # Deletes an analytics configuration for the bucket (specified by the
    # analytics configuration ID).
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutAnalyticsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about the Amazon S3 analytics feature, see [Amazon S3
    # Analytics – Storage Class Analysis][3].
    #
    # The following operations are related to
    # `DeleteBucketAnalyticsConfiguration`:
    #
    # * [GetBucketAnalyticsConfiguration][4]
    #
    # * [ListBucketAnalyticsConfigurations][5]
    #
    # * [PutBucketAnalyticsConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket from which an analytics configuration is
    #   deleted.
    #
    # @option params [required, String] :id
    #   The ID that identifies the analytics configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_analytics_configuration({
    #     bucket: "BucketName", # required
    #     id: "AnalyticsId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketAnalyticsConfiguration AWS API Documentation
    #
    # @overload delete_bucket_analytics_configuration(params = {})
    # @param [Hash] params ({})
    def delete_bucket_analytics_configuration(params = {}, options = {})
      req = build_request(:delete_bucket_analytics_configuration, params)
      req.send_request(options)
    end

    # Deletes the `cors` configuration information set for the bucket.
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutBucketCORS` action. The bucket owner has this permission by
    # default and can grant this permission to others.
    #
    # For information about `cors`, see [Enabling Cross-Origin Resource
    # Sharing][1] in the *Amazon S3 User Guide*.
    #
    # **Related Resources**
    #
    # * [PutBucketCors][2]
    #
    # * [RESTOPTIONSobject][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTOPTIONSobject.html
    #
    # @option params [required, String] :bucket
    #   Specifies the bucket whose `cors` configuration is being deleted.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete cors configuration on a bucket.
    #
    #   # The following example deletes CORS configuration on a bucket.
    #
    #   resp = client.delete_bucket_cors({
    #     bucket: "examplebucket", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_cors({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketCors AWS API Documentation
    #
    # @overload delete_bucket_cors(params = {})
    # @param [Hash] params ({})
    def delete_bucket_cors(params = {}, options = {})
      req = build_request(:delete_bucket_cors, params)
      req.send_request(options)
    end

    # This implementation of the DELETE action resets the default encryption
    # for the bucket as server-side encryption with Amazon S3 managed keys
    # (SSE-S3). For information about the bucket default encryption feature,
    # see [Amazon S3 Bucket Default Encryption][1] in the *Amazon S3 User
    # Guide*.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutEncryptionConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][2] and [Managing Access
    # Permissions to your Amazon S3 Resources][3] in the *Amazon S3 User
    # Guide*.
    #
    # The following operations are related to `DeleteBucketEncryption`:
    #
    # * [PutBucketEncryption][4]
    #
    # * [GetBucketEncryption][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the server-side encryption
    #   configuration to delete.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_encryption({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketEncryption AWS API Documentation
    #
    # @overload delete_bucket_encryption(params = {})
    # @param [Hash] params ({})
    def delete_bucket_encryption(params = {}, options = {})
      req = build_request(:delete_bucket_encryption, params)
      req.send_request(options)
    end

    # Deletes the S3 Intelligent-Tiering configuration from the specified
    # bucket.
    #
    # The S3 Intelligent-Tiering storage class is designed to optimize
    # storage costs by automatically moving data to the most cost-effective
    # storage access tier, without performance impact or operational
    # overhead. S3 Intelligent-Tiering delivers automatic cost savings in
    # three low latency and high throughput access tiers. To get the lowest
    # storage cost on data that can be accessed in minutes to hours, you can
    # choose to activate additional archiving capabilities.
    #
    # The S3 Intelligent-Tiering storage class is the ideal storage class
    # for data with unknown, changing, or unpredictable access patterns,
    # independent of object size or retention period. If the size of an
    # object is less than 128 KB, it is not monitored and not eligible for
    # auto-tiering. Smaller objects can be stored, but they are always
    # charged at the Frequent Access tier rates in the S3
    # Intelligent-Tiering storage class.
    #
    # For more information, see [Storage class for automatically optimizing
    # frequently and infrequently accessed objects][1].
    #
    # Operations related to `DeleteBucketIntelligentTieringConfiguration`
    # include:
    #
    # * [GetBucketIntelligentTieringConfiguration][2]
    #
    # * [PutBucketIntelligentTieringConfiguration][3]
    #
    # * [ListBucketIntelligentTieringConfigurations][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #
    # @option params [required, String] :id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_intelligent_tiering_configuration({
    #     bucket: "BucketName", # required
    #     id: "IntelligentTieringId", # required
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketIntelligentTieringConfiguration AWS API Documentation
    #
    # @overload delete_bucket_intelligent_tiering_configuration(params = {})
    # @param [Hash] params ({})
    def delete_bucket_intelligent_tiering_configuration(params = {}, options = {})
      req = build_request(:delete_bucket_intelligent_tiering_configuration, params)
      req.send_request(options)
    end

    # Deletes an inventory configuration (identified by the inventory ID)
    # from the bucket.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutInventoryConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about the Amazon S3 inventory feature, see [Amazon S3
    # Inventory][3].
    #
    # Operations related to `DeleteBucketInventoryConfiguration` include:
    #
    # * [GetBucketInventoryConfiguration][4]
    #
    # * [PutBucketInventoryConfiguration][5]
    #
    # * [ListBucketInventoryConfigurations][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the inventory configuration to
    #   delete.
    #
    # @option params [required, String] :id
    #   The ID used to identify the inventory configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_inventory_configuration({
    #     bucket: "BucketName", # required
    #     id: "InventoryId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketInventoryConfiguration AWS API Documentation
    #
    # @overload delete_bucket_inventory_configuration(params = {})
    # @param [Hash] params ({})
    def delete_bucket_inventory_configuration(params = {}, options = {})
      req = build_request(:delete_bucket_inventory_configuration, params)
      req.send_request(options)
    end

    # Deletes the lifecycle configuration from the specified bucket. Amazon
    # S3 removes all the lifecycle configuration rules in the lifecycle
    # subresource associated with the bucket. Your objects never expire, and
    # Amazon S3 no longer automatically deletes any objects on the basis of
    # rules contained in the deleted lifecycle configuration.
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutLifecycleConfiguration` action. By default, the bucket owner
    # has this permission and the bucket owner can grant this permission to
    # others.
    #
    # There is usually some time lag before lifecycle configuration deletion
    # is fully propagated to all the Amazon S3 systems.
    #
    # For more information about the object expiration, see [Elements to
    # Describe Lifecycle Actions][1].
    #
    # Related actions include:
    #
    # * [PutBucketLifecycleConfiguration][2]
    #
    # * [GetBucketLifecycleConfiguration][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#intro-lifecycle-rules-actions
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The bucket name of the lifecycle to delete.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete lifecycle configuration on a bucket.
    #
    #   # The following example deletes lifecycle configuration on a bucket.
    #
    #   resp = client.delete_bucket_lifecycle({
    #     bucket: "examplebucket", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_lifecycle({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketLifecycle AWS API Documentation
    #
    # @overload delete_bucket_lifecycle(params = {})
    # @param [Hash] params ({})
    def delete_bucket_lifecycle(params = {}, options = {})
      req = build_request(:delete_bucket_lifecycle, params)
      req.send_request(options)
    end

    # Deletes a metrics configuration for the Amazon CloudWatch request
    # metrics (specified by the metrics configuration ID) from the bucket.
    # Note that this doesn't include the daily storage metrics.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutMetricsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about CloudWatch request metrics for Amazon S3, see
    # [Monitoring Metrics with Amazon CloudWatch][3].
    #
    # The following operations are related to
    # `DeleteBucketMetricsConfiguration`:
    #
    # * [GetBucketMetricsConfiguration][4]
    #
    # * [PutBucketMetricsConfiguration][5]
    #
    # * [ListBucketMetricsConfigurations][6]
    #
    # * [Monitoring Metrics with Amazon CloudWatch][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the metrics configuration to delete.
    #
    # @option params [required, String] :id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_metrics_configuration({
    #     bucket: "BucketName", # required
    #     id: "MetricsId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketMetricsConfiguration AWS API Documentation
    #
    # @overload delete_bucket_metrics_configuration(params = {})
    # @param [Hash] params ({})
    def delete_bucket_metrics_configuration(params = {}, options = {})
      req = build_request(:delete_bucket_metrics_configuration, params)
      req.send_request(options)
    end

    # Removes `OwnershipControls` for an Amazon S3 bucket. To use this
    # operation, you must have the `s3:PutBucketOwnershipControls`
    # permission. For more information about Amazon S3 permissions, see
    # [Specifying Permissions in a Policy][1].
    #
    # For information about Amazon S3 Object Ownership, see [Using Object
    # Ownership][2].
    #
    # The following operations are related to
    # `DeleteBucketOwnershipControls`:
    #
    # * GetBucketOwnershipControls
    #
    # * PutBucketOwnershipControls
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/about-object-ownership.html
    #
    # @option params [required, String] :bucket
    #   The Amazon S3 bucket whose `OwnershipControls` you want to delete.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_ownership_controls({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketOwnershipControls AWS API Documentation
    #
    # @overload delete_bucket_ownership_controls(params = {})
    # @param [Hash] params ({})
    def delete_bucket_ownership_controls(params = {}, options = {})
      req = build_request(:delete_bucket_ownership_controls, params)
      req.send_request(options)
    end

    # This implementation of the DELETE action uses the policy subresource
    # to delete the policy of a specified bucket. If you are using an
    # identity other than the root user of the Amazon Web Services account
    # that owns the bucket, the calling identity must have the
    # `DeleteBucketPolicy` permissions on the specified bucket and belong to
    # the bucket owner's account to use this operation.
    #
    # If you don't have `DeleteBucketPolicy` permissions, Amazon S3 returns
    # a `403 Access Denied` error. If you have the correct permissions, but
    # you're not using an identity that belongs to the bucket owner's
    # account, Amazon S3 returns a `405 Method Not Allowed` error.
    #
    # To ensure that bucket owners don't inadvertently lock themselves out
    # of their own buckets, the root principal in a bucket owner's Amazon
    # Web Services account can perform the `GetBucketPolicy`,
    # `PutBucketPolicy`, and `DeleteBucketPolicy` API actions, even if their
    # bucket policy explicitly denies the root principal's access. Bucket
    # owner root principals can only be blocked from performing these API
    # actions by VPC endpoint policies and Amazon Web Services Organizations
    # policies.
    #
    # For more information about bucket policies, see [Using Bucket Policies
    # and UserPolicies][1].
    #
    # The following operations are related to `DeleteBucketPolicy`
    #
    # * [CreateBucket][2]
    #
    # * [DeleteObject][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete bucket policy
    #
    #   # The following example deletes bucket policy on the specified bucket.
    #
    #   resp = client.delete_bucket_policy({
    #     bucket: "examplebucket", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_policy({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketPolicy AWS API Documentation
    #
    # @overload delete_bucket_policy(params = {})
    # @param [Hash] params ({})
    def delete_bucket_policy(params = {}, options = {})
      req = build_request(:delete_bucket_policy, params)
      req.send_request(options)
    end

    # Deletes the replication configuration from the bucket.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutReplicationConfiguration` action. The bucket owner has these
    # permissions by default and can grant it to others. For more
    # information about permissions, see [Permissions Related to Bucket
    # Subresource Operations][1] and [Managing Access Permissions to Your
    # Amazon S3 Resources][2].
    #
    # <note markdown="1"> It can take a while for the deletion of a replication configuration to
    # fully propagate.
    #
    #  </note>
    #
    # For information about replication configuration, see [Replication][3]
    # in the *Amazon S3 User Guide*.
    #
    # The following operations are related to `DeleteBucketReplication`:
    #
    # * [PutBucketReplication][4]
    #
    # * [GetBucketReplication][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete bucket replication configuration
    #
    #   # The following example deletes replication configuration set on bucket.
    #
    #   resp = client.delete_bucket_replication({
    #     bucket: "example", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_replication({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketReplication AWS API Documentation
    #
    # @overload delete_bucket_replication(params = {})
    # @param [Hash] params ({})
    def delete_bucket_replication(params = {}, options = {})
      req = build_request(:delete_bucket_replication, params)
      req.send_request(options)
    end

    # Deletes the tags from the bucket.
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutBucketTagging` action. By default, the bucket owner has this
    # permission and can grant this permission to others.
    #
    # The following operations are related to `DeleteBucketTagging`:
    #
    # * [GetBucketTagging][1]
    #
    # * [PutBucketTagging][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html
    #
    # @option params [required, String] :bucket
    #   The bucket that has the tag set to be removed.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete bucket tags
    #
    #   # The following example deletes bucket tags.
    #
    #   resp = client.delete_bucket_tagging({
    #     bucket: "examplebucket", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_tagging({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketTagging AWS API Documentation
    #
    # @overload delete_bucket_tagging(params = {})
    # @param [Hash] params ({})
    def delete_bucket_tagging(params = {}, options = {})
      req = build_request(:delete_bucket_tagging, params)
      req.send_request(options)
    end

    # This action removes the website configuration for a bucket. Amazon S3
    # returns a `200 OK` response upon successfully deleting a website
    # configuration on the specified bucket. You will get a `200 OK`
    # response if the website configuration you are trying to delete does
    # not exist on the bucket. Amazon S3 returns a `404` response if the
    # bucket specified in the request does not exist.
    #
    # This DELETE action requires the `S3:DeleteBucketWebsite` permission.
    # By default, only the bucket owner can delete the website configuration
    # attached to a bucket. However, bucket owners can grant other users
    # permission to delete the website configuration by writing a bucket
    # policy granting them the `S3:DeleteBucketWebsite` permission.
    #
    # For more information about hosting websites, see [Hosting Websites on
    # Amazon S3][1].
    #
    # The following operations are related to `DeleteBucketWebsite`:
    #
    # * [GetBucketWebsite][2]
    #
    # * [PutBucketWebsite][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketWebsite.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketWebsite.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which you want to remove the website
    #   configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To delete bucket website configuration
    #
    #   # The following example deletes bucket website configuration.
    #
    #   resp = client.delete_bucket_website({
    #     bucket: "examplebucket", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_bucket_website({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteBucketWebsite AWS API Documentation
    #
    # @overload delete_bucket_website(params = {})
    # @param [Hash] params ({})
    def delete_bucket_website(params = {}, options = {})
      req = build_request(:delete_bucket_website, params)
      req.send_request(options)
    end

    # Removes the null version (if there is one) of an object and inserts a
    # delete marker, which becomes the latest version of the object. If
    # there isn't a null version, Amazon S3 does not remove any objects but
    # will still respond that the command was successful.
    #
    # To remove a specific version, you must use the version Id subresource.
    # Using this subresource permanently deletes the version. If the object
    # deleted is a delete marker, Amazon S3 sets the response header,
    # `x-amz-delete-marker`, to true.
    #
    # If the object you want to delete is in a bucket where the bucket
    # versioning configuration is MFA Delete enabled, you must include the
    # `x-amz-mfa` request header in the DELETE `versionId` request. Requests
    # that include `x-amz-mfa` must use HTTPS.
    #
    # For more information about MFA Delete, see [Using MFA Delete][1]. To
    # see sample requests that use versioning, see [Sample Request][2].
    #
    # You can delete objects by explicitly calling DELETE Object or
    # configure its lifecycle ([PutBucketLifecycle][3]) to enable Amazon S3
    # to remove them for you. If you want to block users or accounts from
    # removing or deleting objects from your bucket, you must deny them the
    # `s3:DeleteObject`, `s3:DeleteObjectVersion`, and
    # `s3:PutLifeCycleConfiguration` actions.
    #
    # The following action is related to `DeleteObject`:
    #
    # * [PutObject][4]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMFADelete.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html#ExampleVersionObjectDelete
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    #
    # @option params [required, String] :bucket
    #   The bucket name of the bucket containing the object.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Key name of the object to delete.
    #
    # @option params [String] :mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication device.
    #   Required to permanently delete a versioned object if versioning is
    #   configured with MFA delete enabled.
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [Boolean] :bypass_governance_retention
    #   Indicates whether S3 Object Lock should bypass Governance-mode
    #   restrictions to process this operation. To use this header, you must
    #   have the `s3:BypassGovernanceRetention` permission.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::DeleteObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DeleteObjectOutput#delete_marker #delete_marker} => Boolean
    #   * {Types::DeleteObjectOutput#version_id #version_id} => String
    #   * {Types::DeleteObjectOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To delete an object
    #
    #   # The following example deletes an object from an S3 bucket.
    #
    #   resp = client.delete_object({
    #     bucket: "examplebucket", 
    #     key: "objectkey.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Example: To delete an object (from a non-versioned bucket)
    #
    #   # The following example deletes an object from a non-versioned bucket.
    #
    #   resp = client.delete_object({
    #     bucket: "ExampleBucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_object({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     mfa: "MFA",
    #     version_id: "ObjectVersionId",
    #     request_payer: "requester", # accepts requester
    #     bypass_governance_retention: false,
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.delete_marker #=> Boolean
    #   resp.version_id #=> String
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObject AWS API Documentation
    #
    # @overload delete_object(params = {})
    # @param [Hash] params ({})
    def delete_object(params = {}, options = {})
      req = build_request(:delete_object, params)
      req.send_request(options)
    end

    # Removes the entire tag set from the specified object. For more
    # information about managing object tags, see [ Object Tagging][1].
    #
    # To use this operation, you must have permission to perform the
    # `s3:DeleteObjectTagging` action.
    #
    # To delete tags of a specific object version, add the `versionId` query
    # parameter in the request. You will need permission for the
    # `s3:DeleteObjectVersionTagging` action.
    #
    # The following operations are related to `DeleteObjectTagging`:
    #
    # * [PutObjectTagging][2]
    #
    # * [GetObjectTagging][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the objects from which to remove the tags.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   The key that identifies the object in the bucket from which to remove
    #   all tags.
    #
    # @option params [String] :version_id
    #   The versionId of the object that the tag-set will be removed from.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::DeleteObjectTaggingOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DeleteObjectTaggingOutput#version_id #version_id} => String
    #
    #
    # @example Example: To remove tag set from an object version
    #
    #   # The following example removes tag set associated with the specified object version. The request specifies both the
    #   # object key and object version.
    #
    #   resp = client.delete_object_tagging({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #     version_id: "ydlaNkwWm0SfKJR.T1b1fIdPRbldTYRI", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     version_id: "ydlaNkwWm0SfKJR.T1b1fIdPRbldTYRI", 
    #   }
    #
    # @example Example: To remove tag set from an object
    #
    #   # The following example removes tag set associated with the specified object. If the bucket is versioning enabled, the
    #   # operation removes tag set from the latest object version.
    #
    #   resp = client.delete_object_tagging({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     version_id: "null", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_object_tagging({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.version_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjectTagging AWS API Documentation
    #
    # @overload delete_object_tagging(params = {})
    # @param [Hash] params ({})
    def delete_object_tagging(params = {}, options = {})
      req = build_request(:delete_object_tagging, params)
      req.send_request(options)
    end

    # This action enables you to delete multiple objects from a bucket using
    # a single HTTP request. If you know the object keys that you want to
    # delete, then this action provides a suitable alternative to sending
    # individual delete requests, reducing per-request overhead.
    #
    # The request contains a list of up to 1000 keys that you want to
    # delete. In the XML, you provide the object key names, and optionally,
    # version IDs if you want to delete a specific version of the object
    # from a versioning-enabled bucket. For each key, Amazon S3 performs a
    # delete action and returns the result of that delete, success, or
    # failure, in the response. Note that if the object specified in the
    # request is not found, Amazon S3 returns the result as deleted.
    #
    # The action supports two modes for the response: verbose and quiet. By
    # default, the action uses verbose mode in which the response includes
    # the result of deletion of each key in your request. In quiet mode the
    # response includes only keys where the delete action encountered an
    # error. For a successful deletion, the action does not return any
    # information about the delete in the response body.
    #
    # When performing this action on an MFA Delete enabled bucket, that
    # attempts to delete any versioned objects, you must include an MFA
    # token. If you do not provide one, the entire request will fail, even
    # if there are non-versioned objects you are trying to delete. If you
    # provide an invalid token, whether there are versioned keys in the
    # request or not, the entire Multi-Object Delete request will fail. For
    # information about MFA Delete, see [ MFA Delete][1].
    #
    # Finally, the Content-MD5 header is required for all Multi-Object
    # Delete requests. Amazon S3 uses the header value to ensure that your
    # request body has not been altered in transit.
    #
    # The following operations are related to `DeleteObjects`:
    #
    # * [CreateMultipartUpload][2]
    #
    # * [UploadPart][3]
    #
    # * [CompleteMultipartUpload][4]
    #
    # * [ListParts][5]
    #
    # * [AbortMultipartUpload][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html#MultiFactorAuthenticationDelete
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the objects to delete.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, Types::Delete] :delete
    #   Container for the request.
    #
    # @option params [String] :mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication device.
    #   Required to permanently delete a versioned object if versioning is
    #   configured with MFA delete enabled.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [Boolean] :bypass_governance_retention
    #   Specifies whether you want to delete this object even if it has a
    #   Governance-type Object Lock in place. To use this header, you must
    #   have the `s3:BypassGovernanceRetention` permission.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #   This checksum algorithm must be the same for all parts and it match
    #   the checksum value supplied in the `CreateMultipartUpload` request.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @return [Types::DeleteObjectsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DeleteObjectsOutput#deleted #deleted} => Array&lt;Types::DeletedObject&gt;
    #   * {Types::DeleteObjectsOutput#request_charged #request_charged} => String
    #   * {Types::DeleteObjectsOutput#errors #errors} => Array&lt;Types::Error&gt;
    #
    #
    # @example Example: To delete multiple objects from a versioned bucket
    #
    #   # The following example deletes objects from a bucket. The bucket is versioned, and the request does not specify the
    #   # object version to delete. In this case, all versions remain in the bucket and S3 adds a delete marker.
    #
    #   resp = client.delete_objects({
    #     bucket: "examplebucket", 
    #     delete: {
    #       objects: [
    #         {
    #           key: "objectkey1", 
    #         }, 
    #         {
    #           key: "objectkey2", 
    #         }, 
    #       ], 
    #       quiet: false, 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     deleted: [
    #       {
    #         delete_marker: true, 
    #         delete_marker_version_id: "A._w1z6EFiCF5uhtQMDal9JDkID9tQ7F", 
    #         key: "objectkey1", 
    #       }, 
    #       {
    #         delete_marker: true, 
    #         delete_marker_version_id: "iOd_ORxhkKe_e8G8_oSGxt2PjsCZKlkt", 
    #         key: "objectkey2", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Example: To delete multiple object versions from a versioned bucket
    #
    #   # The following example deletes objects from a bucket. The request specifies object versions. S3 deletes specific object
    #   # versions and returns the key and versions of deleted objects in the response.
    #
    #   resp = client.delete_objects({
    #     bucket: "examplebucket", 
    #     delete: {
    #       objects: [
    #         {
    #           key: "HappyFace.jpg", 
    #           version_id: "2LWg7lQLnY41.maGB5Z6SWW.dcq0vx7b", 
    #         }, 
    #         {
    #           key: "HappyFace.jpg", 
    #           version_id: "yoz3HB.ZhCS_tKVEmIOr7qYyyAaZSKVd", 
    #         }, 
    #       ], 
    #       quiet: false, 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     deleted: [
    #       {
    #         key: "HappyFace.jpg", 
    #         version_id: "yoz3HB.ZhCS_tKVEmIOr7qYyyAaZSKVd", 
    #       }, 
    #       {
    #         key: "HappyFace.jpg", 
    #         version_id: "2LWg7lQLnY41.maGB5Z6SWW.dcq0vx7b", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_objects({
    #     bucket: "BucketName", # required
    #     delete: { # required
    #       objects: [ # required
    #         {
    #           key: "ObjectKey", # required
    #           version_id: "ObjectVersionId",
    #         },
    #       ],
    #       quiet: false,
    #     },
    #     mfa: "MFA",
    #     request_payer: "requester", # accepts requester
    #     bypass_governance_retention: false,
    #     expected_bucket_owner: "AccountId",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #   })
    #
    # @example Response structure
    #
    #   resp.deleted #=> Array
    #   resp.deleted[0].key #=> String
    #   resp.deleted[0].version_id #=> String
    #   resp.deleted[0].delete_marker #=> Boolean
    #   resp.deleted[0].delete_marker_version_id #=> String
    #   resp.request_charged #=> String, one of "requester"
    #   resp.errors #=> Array
    #   resp.errors[0].key #=> String
    #   resp.errors[0].version_id #=> String
    #   resp.errors[0].code #=> String
    #   resp.errors[0].message #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeleteObjects AWS API Documentation
    #
    # @overload delete_objects(params = {})
    # @param [Hash] params ({})
    def delete_objects(params = {}, options = {})
      req = build_request(:delete_objects, params)
      req.send_request(options)
    end

    # Removes the `PublicAccessBlock` configuration for an Amazon S3 bucket.
    # To use this operation, you must have the
    # `s3:PutBucketPublicAccessBlock` permission. For more information about
    # permissions, see [Permissions Related to Bucket Subresource
    # Operations][1] and [Managing Access Permissions to Your Amazon S3
    # Resources][2].
    #
    # The following operations are related to `DeletePublicAccessBlock`:
    #
    # * [Using Amazon S3 Block Public Access][3]
    #
    # * [GetPublicAccessBlock][4]
    #
    # * [PutPublicAccessBlock][5]
    #
    # * [GetBucketPolicyStatus][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html
    #
    # @option params [required, String] :bucket
    #   The Amazon S3 bucket whose `PublicAccessBlock` configuration you want
    #   to delete.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.delete_public_access_block({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/DeletePublicAccessBlock AWS API Documentation
    #
    # @overload delete_public_access_block(params = {})
    # @param [Hash] params ({})
    def delete_public_access_block(params = {}, options = {})
      req = build_request(:delete_public_access_block, params)
      req.send_request(options)
    end

    # This implementation of the GET action uses the `accelerate`
    # subresource to return the Transfer Acceleration state of a bucket,
    # which is either `Enabled` or `Suspended`. Amazon S3 Transfer
    # Acceleration is a bucket-level feature that enables you to perform
    # faster data transfers to and from Amazon S3.
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetAccelerateConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to your Amazon S3 Resources][2] in the *Amazon S3 User
    # Guide*.
    #
    # You set the Transfer Acceleration state of an existing bucket to
    # `Enabled` or `Suspended` by using the
    # [PutBucketAccelerateConfiguration][3] operation.
    #
    # A GET `accelerate` request does not return a state value for a bucket
    # that has no transfer acceleration state. A bucket has no Transfer
    # Acceleration state if a state has never been set on the bucket.
    #
    # For more information about transfer acceleration, see [Transfer
    # Acceleration][4] in the Amazon S3 User Guide.
    #
    # The following operations are related to
    # `GetBucketAccelerateConfiguration`:
    #
    # * [PutBucketAccelerateConfiguration][3]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAccelerateConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which the accelerate configuration is
    #   retrieved.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @return [Types::GetBucketAccelerateConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketAccelerateConfigurationOutput#status #status} => String
    #   * {Types::GetBucketAccelerateConfigurationOutput#request_charged #request_charged} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_accelerate_configuration({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #     request_payer: "requester", # accepts requester
    #   })
    #
    # @example Response structure
    #
    #   resp.status #=> String, one of "Enabled", "Suspended"
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAccelerateConfiguration AWS API Documentation
    #
    # @overload get_bucket_accelerate_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_accelerate_configuration(params = {}, options = {})
      req = build_request(:get_bucket_accelerate_configuration, params)
      req.send_request(options)
    end

    # This implementation of the `GET` action uses the `acl` subresource to
    # return the access control list (ACL) of a bucket. To use `GET` to
    # return the ACL of the bucket, you must have `READ_ACP` access to the
    # bucket. If `READ_ACP` permission is granted to the anonymous user, you
    # can return the ACL of the bucket without using an authorization
    # header.
    #
    # To use this API operation against an access point, provide the alias
    # of the access point in place of the bucket name.
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][1].
    #
    # <note markdown="1"> If your bucket uses the bucket owner enforced setting for S3 Object
    # Ownership, requests to read ACLs are still supported and return the
    # `bucket-owner-full-control` ACL with the owner being the account that
    # created the bucket. For more information, see [ Controlling object
    # ownership and disabling ACLs][2] in the *Amazon S3 User Guide*.
    #
    #  </note>
    #
    # The following operations are related to `GetBucketAcl`:
    #
    # * [ListObjects][3]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html
    #
    # @option params [required, String] :bucket
    #   Specifies the S3 bucket whose ACL is being requested.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketAclOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketAclOutput#owner #owner} => Types::Owner
    #   * {Types::GetBucketAclOutput#grants #grants} => Array&lt;Types::Grant&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_acl({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.owner.display_name #=> String
    #   resp.owner.id #=> String
    #   resp.grants #=> Array
    #   resp.grants[0].grantee.display_name #=> String
    #   resp.grants[0].grantee.email_address #=> String
    #   resp.grants[0].grantee.id #=> String
    #   resp.grants[0].grantee.type #=> String, one of "CanonicalUser", "AmazonCustomerByEmail", "Group"
    #   resp.grants[0].grantee.uri #=> String
    #   resp.grants[0].permission #=> String, one of "FULL_CONTROL", "WRITE", "WRITE_ACP", "READ", "READ_ACP"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAcl AWS API Documentation
    #
    # @overload get_bucket_acl(params = {})
    # @param [Hash] params ({})
    def get_bucket_acl(params = {}, options = {})
      req = build_request(:get_bucket_acl, params)
      req.send_request(options)
    end

    # This implementation of the GET action returns an analytics
    # configuration (identified by the analytics configuration ID) from the
    # bucket.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetAnalyticsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [ Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2] in the *Amazon S3 User
    # Guide*.
    #
    # For information about Amazon S3 analytics feature, see [Amazon S3
    # Analytics – Storage Class Analysis][3] in the *Amazon S3 User Guide*.
    #
    # The following operations are related to
    # `GetBucketAnalyticsConfiguration`:
    #
    # * [DeleteBucketAnalyticsConfiguration][4]
    #
    # * [ListBucketAnalyticsConfigurations][5]
    #
    # * [PutBucketAnalyticsConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket from which an analytics configuration is
    #   retrieved.
    #
    # @option params [required, String] :id
    #   The ID that identifies the analytics configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketAnalyticsConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketAnalyticsConfigurationOutput#analytics_configuration #analytics_configuration} => Types::AnalyticsConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_analytics_configuration({
    #     bucket: "BucketName", # required
    #     id: "AnalyticsId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.analytics_configuration.id #=> String
    #   resp.analytics_configuration.filter.prefix #=> String
    #   resp.analytics_configuration.filter.tag.key #=> String
    #   resp.analytics_configuration.filter.tag.value #=> String
    #   resp.analytics_configuration.filter.and.prefix #=> String
    #   resp.analytics_configuration.filter.and.tags #=> Array
    #   resp.analytics_configuration.filter.and.tags[0].key #=> String
    #   resp.analytics_configuration.filter.and.tags[0].value #=> String
    #   resp.analytics_configuration.storage_class_analysis.data_export.output_schema_version #=> String, one of "V_1"
    #   resp.analytics_configuration.storage_class_analysis.data_export.destination.s3_bucket_destination.format #=> String, one of "CSV"
    #   resp.analytics_configuration.storage_class_analysis.data_export.destination.s3_bucket_destination.bucket_account_id #=> String
    #   resp.analytics_configuration.storage_class_analysis.data_export.destination.s3_bucket_destination.bucket #=> String
    #   resp.analytics_configuration.storage_class_analysis.data_export.destination.s3_bucket_destination.prefix #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketAnalyticsConfiguration AWS API Documentation
    #
    # @overload get_bucket_analytics_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_analytics_configuration(params = {}, options = {})
      req = build_request(:get_bucket_analytics_configuration, params)
      req.send_request(options)
    end

    # Returns the Cross-Origin Resource Sharing (CORS) configuration
    # information set for the bucket.
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetBucketCORS` action. By default, the bucket owner has this
    # permission and can grant it to others.
    #
    # To use this API operation against an access point, provide the alias
    # of the access point in place of the bucket name.
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][1].
    #
    # For more information about CORS, see [ Enabling Cross-Origin Resource
    # Sharing][2].
    #
    # The following operations are related to `GetBucketCors`:
    #
    # * [PutBucketCors][3]
    #
    # * [DeleteBucketCors][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketCors.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which to get the cors configuration.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketCorsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketCorsOutput#cors_rules #cors_rules} => Array&lt;Types::CORSRule&gt;
    #
    #
    # @example Example: To get cors configuration set on a bucket
    #
    #   # The following example returns cross-origin resource sharing (CORS) configuration set on a bucket.
    #
    #   resp = client.get_bucket_cors({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     cors_rules: [
    #       {
    #         allowed_headers: [
    #           "Authorization", 
    #         ], 
    #         allowed_methods: [
    #           "GET", 
    #         ], 
    #         allowed_origins: [
    #           "*", 
    #         ], 
    #         max_age_seconds: 3000, 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_cors({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.cors_rules #=> Array
    #   resp.cors_rules[0].id #=> String
    #   resp.cors_rules[0].allowed_headers #=> Array
    #   resp.cors_rules[0].allowed_headers[0] #=> String
    #   resp.cors_rules[0].allowed_methods #=> Array
    #   resp.cors_rules[0].allowed_methods[0] #=> String
    #   resp.cors_rules[0].allowed_origins #=> Array
    #   resp.cors_rules[0].allowed_origins[0] #=> String
    #   resp.cors_rules[0].expose_headers #=> Array
    #   resp.cors_rules[0].expose_headers[0] #=> String
    #   resp.cors_rules[0].max_age_seconds #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketCors AWS API Documentation
    #
    # @overload get_bucket_cors(params = {})
    # @param [Hash] params ({})
    def get_bucket_cors(params = {}, options = {})
      req = build_request(:get_bucket_cors, params)
      req.send_request(options)
    end

    # Returns the default encryption configuration for an Amazon S3 bucket.
    # By default, all buckets have a default encryption configuration that
    # uses server-side encryption with Amazon S3 managed keys (SSE-S3). For
    # information about the bucket default encryption feature, see [Amazon
    # S3 Bucket Default Encryption][1] in the *Amazon S3 User Guide*.
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetEncryptionConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][2] and [Managing Access
    # Permissions to Your Amazon S3 Resources][3].
    #
    # The following operations are related to `GetBucketEncryption`:
    #
    # * [PutBucketEncryption][4]
    #
    # * [DeleteBucketEncryption][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketEncryption.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket from which the server-side encryption
    #   configuration is retrieved.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketEncryptionOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketEncryptionOutput#server_side_encryption_configuration #server_side_encryption_configuration} => Types::ServerSideEncryptionConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_encryption({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.server_side_encryption_configuration.rules #=> Array
    #   resp.server_side_encryption_configuration.rules[0].apply_server_side_encryption_by_default.sse_algorithm #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.server_side_encryption_configuration.rules[0].apply_server_side_encryption_by_default.kms_master_key_id #=> String
    #   resp.server_side_encryption_configuration.rules[0].bucket_key_enabled #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketEncryption AWS API Documentation
    #
    # @overload get_bucket_encryption(params = {})
    # @param [Hash] params ({})
    def get_bucket_encryption(params = {}, options = {})
      req = build_request(:get_bucket_encryption, params)
      req.send_request(options)
    end

    # Gets the S3 Intelligent-Tiering configuration from the specified
    # bucket.
    #
    # The S3 Intelligent-Tiering storage class is designed to optimize
    # storage costs by automatically moving data to the most cost-effective
    # storage access tier, without performance impact or operational
    # overhead. S3 Intelligent-Tiering delivers automatic cost savings in
    # three low latency and high throughput access tiers. To get the lowest
    # storage cost on data that can be accessed in minutes to hours, you can
    # choose to activate additional archiving capabilities.
    #
    # The S3 Intelligent-Tiering storage class is the ideal storage class
    # for data with unknown, changing, or unpredictable access patterns,
    # independent of object size or retention period. If the size of an
    # object is less than 128 KB, it is not monitored and not eligible for
    # auto-tiering. Smaller objects can be stored, but they are always
    # charged at the Frequent Access tier rates in the S3
    # Intelligent-Tiering storage class.
    #
    # For more information, see [Storage class for automatically optimizing
    # frequently and infrequently accessed objects][1].
    #
    # Operations related to `GetBucketIntelligentTieringConfiguration`
    # include:
    #
    # * [DeleteBucketIntelligentTieringConfiguration][2]
    #
    # * [PutBucketIntelligentTieringConfiguration][3]
    #
    # * [ListBucketIntelligentTieringConfigurations][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #
    # @option params [required, String] :id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #
    # @return [Types::GetBucketIntelligentTieringConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketIntelligentTieringConfigurationOutput#intelligent_tiering_configuration #intelligent_tiering_configuration} => Types::IntelligentTieringConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_intelligent_tiering_configuration({
    #     bucket: "BucketName", # required
    #     id: "IntelligentTieringId", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.intelligent_tiering_configuration.id #=> String
    #   resp.intelligent_tiering_configuration.filter.prefix #=> String
    #   resp.intelligent_tiering_configuration.filter.tag.key #=> String
    #   resp.intelligent_tiering_configuration.filter.tag.value #=> String
    #   resp.intelligent_tiering_configuration.filter.and.prefix #=> String
    #   resp.intelligent_tiering_configuration.filter.and.tags #=> Array
    #   resp.intelligent_tiering_configuration.filter.and.tags[0].key #=> String
    #   resp.intelligent_tiering_configuration.filter.and.tags[0].value #=> String
    #   resp.intelligent_tiering_configuration.status #=> String, one of "Enabled", "Disabled"
    #   resp.intelligent_tiering_configuration.tierings #=> Array
    #   resp.intelligent_tiering_configuration.tierings[0].days #=> Integer
    #   resp.intelligent_tiering_configuration.tierings[0].access_tier #=> String, one of "ARCHIVE_ACCESS", "DEEP_ARCHIVE_ACCESS"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketIntelligentTieringConfiguration AWS API Documentation
    #
    # @overload get_bucket_intelligent_tiering_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_intelligent_tiering_configuration(params = {}, options = {})
      req = build_request(:get_bucket_intelligent_tiering_configuration, params)
      req.send_request(options)
    end

    # Returns an inventory configuration (identified by the inventory
    # configuration ID) from the bucket.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetInventoryConfiguration` action. The bucket owner has this
    # permission by default and can grant this permission to others. For
    # more information about permissions, see [Permissions Related to Bucket
    # Subresource Operations][1] and [Managing Access Permissions to Your
    # Amazon S3 Resources][2].
    #
    # For information about the Amazon S3 inventory feature, see [Amazon S3
    # Inventory][3].
    #
    # The following operations are related to
    # `GetBucketInventoryConfiguration`:
    #
    # * [DeleteBucketInventoryConfiguration][4]
    #
    # * [ListBucketInventoryConfigurations][5]
    #
    # * [PutBucketInventoryConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the inventory configuration to
    #   retrieve.
    #
    # @option params [required, String] :id
    #   The ID used to identify the inventory configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketInventoryConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketInventoryConfigurationOutput#inventory_configuration #inventory_configuration} => Types::InventoryConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_inventory_configuration({
    #     bucket: "BucketName", # required
    #     id: "InventoryId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.inventory_configuration.destination.s3_bucket_destination.account_id #=> String
    #   resp.inventory_configuration.destination.s3_bucket_destination.bucket #=> String
    #   resp.inventory_configuration.destination.s3_bucket_destination.format #=> String, one of "CSV", "ORC", "Parquet"
    #   resp.inventory_configuration.destination.s3_bucket_destination.prefix #=> String
    #   resp.inventory_configuration.destination.s3_bucket_destination.encryption.ssekms.key_id #=> String
    #   resp.inventory_configuration.is_enabled #=> Boolean
    #   resp.inventory_configuration.filter.prefix #=> String
    #   resp.inventory_configuration.id #=> String
    #   resp.inventory_configuration.included_object_versions #=> String, one of "All", "Current"
    #   resp.inventory_configuration.optional_fields #=> Array
    #   resp.inventory_configuration.optional_fields[0] #=> String, one of "Size", "LastModifiedDate", "StorageClass", "ETag", "IsMultipartUploaded", "ReplicationStatus", "EncryptionStatus", "ObjectLockRetainUntilDate", "ObjectLockMode", "ObjectLockLegalHoldStatus", "IntelligentTieringAccessTier", "BucketKeyStatus", "ChecksumAlgorithm"
    #   resp.inventory_configuration.schedule.frequency #=> String, one of "Daily", "Weekly"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketInventoryConfiguration AWS API Documentation
    #
    # @overload get_bucket_inventory_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_inventory_configuration(params = {}, options = {})
      req = build_request(:get_bucket_inventory_configuration, params)
      req.send_request(options)
    end

    # For an updated version of this API, see
    # [GetBucketLifecycleConfiguration][1]. If you configured a bucket
    # lifecycle using the `filter` element, you should see the updated
    # version of this topic. This topic is provided for backward
    # compatibility.
    #
    # Returns the lifecycle configuration information set on the bucket. For
    # information about lifecycle configuration, see [Object Lifecycle
    # Management][2].
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetLifecycleConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][3] and [Managing Access
    # Permissions to Your Amazon S3 Resources][4].
    #
    # `GetBucketLifecycle` has the following special error:
    #
    # * Error code: `NoSuchLifecycleConfiguration`
    #
    #   * Description: The lifecycle configuration does not exist.
    #
    #   * HTTP Status Code: 404 Not Found
    #
    #   * SOAP Fault Code Prefix: Client
    #
    # The following operations are related to `GetBucketLifecycle`:
    #
    # * [GetBucketLifecycleConfiguration][1]
    #
    # * [PutBucketLifecycle][5]
    #
    # * [DeleteBucketLifecycle][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the lifecycle information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketLifecycleOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketLifecycleOutput#rules #rules} => Array&lt;Types::Rule&gt;
    #
    #
    # @example Example: To get a bucket acl
    #
    #   # The following example gets ACL on the specified bucket.
    #
    #   resp = client.get_bucket_lifecycle({
    #     bucket: "acl1", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     rules: [
    #       {
    #         expiration: {
    #           days: 1, 
    #         }, 
    #         id: "delete logs", 
    #         prefix: "123/", 
    #         status: "Enabled", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_lifecycle({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.rules #=> Array
    #   resp.rules[0].expiration.date #=> Time
    #   resp.rules[0].expiration.days #=> Integer
    #   resp.rules[0].expiration.expired_object_delete_marker #=> Boolean
    #   resp.rules[0].id #=> String
    #   resp.rules[0].prefix #=> String
    #   resp.rules[0].status #=> String, one of "Enabled", "Disabled"
    #   resp.rules[0].transition.date #=> Time
    #   resp.rules[0].transition.days #=> Integer
    #   resp.rules[0].transition.storage_class #=> String, one of "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "GLACIER_IR"
    #   resp.rules[0].noncurrent_version_transition.noncurrent_days #=> Integer
    #   resp.rules[0].noncurrent_version_transition.storage_class #=> String, one of "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "GLACIER_IR"
    #   resp.rules[0].noncurrent_version_transition.newer_noncurrent_versions #=> Integer
    #   resp.rules[0].noncurrent_version_expiration.noncurrent_days #=> Integer
    #   resp.rules[0].noncurrent_version_expiration.newer_noncurrent_versions #=> Integer
    #   resp.rules[0].abort_incomplete_multipart_upload.days_after_initiation #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycle AWS API Documentation
    #
    # @overload get_bucket_lifecycle(params = {})
    # @param [Hash] params ({})
    def get_bucket_lifecycle(params = {}, options = {})
      req = build_request(:get_bucket_lifecycle, params)
      req.send_request(options)
    end

    # <note markdown="1"> Bucket lifecycle configuration now supports specifying a lifecycle
    # rule using an object key name prefix, one or more object tags, or a
    # combination of both. Accordingly, this section describes the latest
    # API. The response describes the new filter element that you can use to
    # specify a filter to select a subset of objects to which the rule
    # applies. If you are using a previous version of the lifecycle
    # configuration, it still works. For the earlier action, see
    # [GetBucketLifecycle][1].
    #
    #  </note>
    #
    # Returns the lifecycle configuration information set on the bucket. For
    # information about lifecycle configuration, see [Object Lifecycle
    # Management][2].
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetLifecycleConfiguration` action. The bucket owner has this
    # permission, by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][3] and [Managing Access
    # Permissions to Your Amazon S3 Resources][4].
    #
    # `GetBucketLifecycleConfiguration` has the following special error:
    #
    # * Error code: `NoSuchLifecycleConfiguration`
    #
    #   * Description: The lifecycle configuration does not exist.
    #
    #   * HTTP Status Code: 404 Not Found
    #
    #   * SOAP Fault Code Prefix: Client
    #
    # The following operations are related to
    # `GetBucketLifecycleConfiguration`:
    #
    # * [GetBucketLifecycle][1]
    #
    # * [PutBucketLifecycle][5]
    #
    # * [DeleteBucketLifecycle][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycle.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the lifecycle information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketLifecycleConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketLifecycleConfigurationOutput#rules #rules} => Array&lt;Types::LifecycleRule&gt;
    #
    #
    # @example Example: To get lifecycle configuration on a bucket
    #
    #   # The following example retrieves lifecycle configuration on set on a bucket. 
    #
    #   resp = client.get_bucket_lifecycle_configuration({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     rules: [
    #       {
    #         id: "Rule for TaxDocs/", 
    #         prefix: "TaxDocs", 
    #         status: "Enabled", 
    #         transitions: [
    #           {
    #             days: 365, 
    #             storage_class: "STANDARD_IA", 
    #           }, 
    #         ], 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_lifecycle_configuration({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.rules #=> Array
    #   resp.rules[0].expiration.date #=> Time
    #   resp.rules[0].expiration.days #=> Integer
    #   resp.rules[0].expiration.expired_object_delete_marker #=> Boolean
    #   resp.rules[0].id #=> String
    #   resp.rules[0].prefix #=> String
    #   resp.rules[0].filter.prefix #=> String
    #   resp.rules[0].filter.tag.key #=> String
    #   resp.rules[0].filter.tag.value #=> String
    #   resp.rules[0].filter.object_size_greater_than #=> Integer
    #   resp.rules[0].filter.object_size_less_than #=> Integer
    #   resp.rules[0].filter.and.prefix #=> String
    #   resp.rules[0].filter.and.tags #=> Array
    #   resp.rules[0].filter.and.tags[0].key #=> String
    #   resp.rules[0].filter.and.tags[0].value #=> String
    #   resp.rules[0].filter.and.object_size_greater_than #=> Integer
    #   resp.rules[0].filter.and.object_size_less_than #=> Integer
    #   resp.rules[0].status #=> String, one of "Enabled", "Disabled"
    #   resp.rules[0].transitions #=> Array
    #   resp.rules[0].transitions[0].date #=> Time
    #   resp.rules[0].transitions[0].days #=> Integer
    #   resp.rules[0].transitions[0].storage_class #=> String, one of "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "GLACIER_IR"
    #   resp.rules[0].noncurrent_version_transitions #=> Array
    #   resp.rules[0].noncurrent_version_transitions[0].noncurrent_days #=> Integer
    #   resp.rules[0].noncurrent_version_transitions[0].storage_class #=> String, one of "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "GLACIER_IR"
    #   resp.rules[0].noncurrent_version_transitions[0].newer_noncurrent_versions #=> Integer
    #   resp.rules[0].noncurrent_version_expiration.noncurrent_days #=> Integer
    #   resp.rules[0].noncurrent_version_expiration.newer_noncurrent_versions #=> Integer
    #   resp.rules[0].abort_incomplete_multipart_upload.days_after_initiation #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLifecycleConfiguration AWS API Documentation
    #
    # @overload get_bucket_lifecycle_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_lifecycle_configuration(params = {}, options = {})
      req = build_request(:get_bucket_lifecycle_configuration, params)
      req.send_request(options)
    end

    # Returns the Region the bucket resides in. You set the bucket's Region
    # using the `LocationConstraint` request parameter in a `CreateBucket`
    # request. For more information, see [CreateBucket][1].
    #
    # To use this API operation against an access point, provide the alias
    # of the access point in place of the bucket name.
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][2].
    #
    # <note markdown="1"> We recommend that you use [HeadBucket][3] to return the Region that a
    # bucket resides in. For backward compatibility, Amazon S3 continues to
    # support GetBucketLocation.
    #
    #  </note>
    #
    # The following operations are related to `GetBucketLocation`:
    #
    # * [GetObject][4]
    #
    # * [CreateBucket][1]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadBucket.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the location.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketLocationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketLocationOutput#location_constraint #location_constraint} => String
    #
    #
    # @example Example: To get bucket location
    #
    #   # The following example returns bucket location.
    #
    #   resp = client.get_bucket_location({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     location_constraint: "us-west-2", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_location({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.location_constraint #=> String, one of "af-south-1", "ap-east-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3", "ap-south-1", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", "ca-central-1", "cn-north-1", "cn-northwest-1", "EU", "eu-central-1", "eu-north-1", "eu-south-1", "eu-west-1", "eu-west-2", "eu-west-3", "me-south-1", "sa-east-1", "us-east-2", "us-gov-east-1", "us-gov-west-1", "us-west-1", "us-west-2"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLocation AWS API Documentation
    #
    # @overload get_bucket_location(params = {})
    # @param [Hash] params ({})
    def get_bucket_location(params = {}, options = {})
      req = build_request(:get_bucket_location, params)
      req.send_request(options)
    end

    # Returns the logging status of a bucket and the permissions users have
    # to view and modify that status.
    #
    # The following operations are related to `GetBucketLogging`:
    #
    # * [CreateBucket][1]
    #
    # * [PutBucketLogging][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLogging.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which to get the logging information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketLoggingOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketLoggingOutput#logging_enabled #logging_enabled} => Types::LoggingEnabled
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_logging({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.logging_enabled.target_bucket #=> String
    #   resp.logging_enabled.target_grants #=> Array
    #   resp.logging_enabled.target_grants[0].grantee.display_name #=> String
    #   resp.logging_enabled.target_grants[0].grantee.email_address #=> String
    #   resp.logging_enabled.target_grants[0].grantee.id #=> String
    #   resp.logging_enabled.target_grants[0].grantee.type #=> String, one of "CanonicalUser", "AmazonCustomerByEmail", "Group"
    #   resp.logging_enabled.target_grants[0].grantee.uri #=> String
    #   resp.logging_enabled.target_grants[0].permission #=> String, one of "FULL_CONTROL", "READ", "WRITE"
    #   resp.logging_enabled.target_prefix #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketLogging AWS API Documentation
    #
    # @overload get_bucket_logging(params = {})
    # @param [Hash] params ({})
    def get_bucket_logging(params = {}, options = {})
      req = build_request(:get_bucket_logging, params)
      req.send_request(options)
    end

    # Gets a metrics configuration (specified by the metrics configuration
    # ID) from the bucket. Note that this doesn't include the daily storage
    # metrics.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetMetricsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about CloudWatch request metrics for Amazon S3, see
    # [Monitoring Metrics with Amazon CloudWatch][3].
    #
    # The following operations are related to
    # `GetBucketMetricsConfiguration`:
    #
    # * [PutBucketMetricsConfiguration][4]
    #
    # * [DeleteBucketMetricsConfiguration][5]
    #
    # * [ListBucketMetricsConfigurations][6]
    #
    # * [Monitoring Metrics with Amazon CloudWatch][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the metrics configuration to
    #   retrieve.
    #
    # @option params [required, String] :id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketMetricsConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketMetricsConfigurationOutput#metrics_configuration #metrics_configuration} => Types::MetricsConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_metrics_configuration({
    #     bucket: "BucketName", # required
    #     id: "MetricsId", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.metrics_configuration.id #=> String
    #   resp.metrics_configuration.filter.prefix #=> String
    #   resp.metrics_configuration.filter.tag.key #=> String
    #   resp.metrics_configuration.filter.tag.value #=> String
    #   resp.metrics_configuration.filter.access_point_arn #=> String
    #   resp.metrics_configuration.filter.and.prefix #=> String
    #   resp.metrics_configuration.filter.and.tags #=> Array
    #   resp.metrics_configuration.filter.and.tags[0].key #=> String
    #   resp.metrics_configuration.filter.and.tags[0].value #=> String
    #   resp.metrics_configuration.filter.and.access_point_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketMetricsConfiguration AWS API Documentation
    #
    # @overload get_bucket_metrics_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_metrics_configuration(params = {}, options = {})
      req = build_request(:get_bucket_metrics_configuration, params)
      req.send_request(options)
    end

    # No longer used, see [GetBucketNotificationConfiguration][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the notification
    #   configuration.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::NotificationConfigurationDeprecated] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::NotificationConfigurationDeprecated#topic_configuration #topic_configuration} => Types::TopicConfigurationDeprecated
    #   * {Types::NotificationConfigurationDeprecated#queue_configuration #queue_configuration} => Types::QueueConfigurationDeprecated
    #   * {Types::NotificationConfigurationDeprecated#cloud_function_configuration #cloud_function_configuration} => Types::CloudFunctionConfiguration
    #
    #
    # @example Example: To get notification configuration set on a bucket
    #
    #   # The following example returns notification configuration set on a bucket.
    #
    #   resp = client.get_bucket_notification({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     queue_configuration: {
    #       event: "s3:ObjectCreated:Put", 
    #       events: [
    #         "s3:ObjectCreated:Put", 
    #       ], 
    #       id: "MDQ2OGQ4NDEtOTBmNi00YTM4LTk0NzYtZDIwN2I3NWQ1NjIx", 
    #       queue: "arn:aws:sqs:us-east-1:acct-id:S3ObjectCreatedEventQueue", 
    #     }, 
    #     topic_configuration: {
    #       event: "s3:ObjectCreated:Copy", 
    #       events: [
    #         "s3:ObjectCreated:Copy", 
    #       ], 
    #       id: "YTVkMWEzZGUtNTY1NS00ZmE2LWJjYjktMmRlY2QwODFkNTJi", 
    #       topic: "arn:aws:sns:us-east-1:acct-id:S3ObjectCreatedEventTopic", 
    #     }, 
    #   }
    #
    # @example Example: To get notification configuration set on a bucket
    #
    #   # The following example returns notification configuration set on a bucket.
    #
    #   resp = client.get_bucket_notification({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     queue_configuration: {
    #       event: "s3:ObjectCreated:Put", 
    #       events: [
    #         "s3:ObjectCreated:Put", 
    #       ], 
    #       id: "MDQ2OGQ4NDEtOTBmNi00YTM4LTk0NzYtZDIwN2I3NWQ1NjIx", 
    #       queue: "arn:aws:sqs:us-east-1:acct-id:S3ObjectCreatedEventQueue", 
    #     }, 
    #     topic_configuration: {
    #       event: "s3:ObjectCreated:Copy", 
    #       events: [
    #         "s3:ObjectCreated:Copy", 
    #       ], 
    #       id: "YTVkMWEzZGUtNTY1NS00ZmE2LWJjYjktMmRlY2QwODFkNTJi", 
    #       topic: "arn:aws:sns:us-east-1:acct-id:S3ObjectCreatedEventTopic", 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_notification({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.topic_configuration.id #=> String
    #   resp.topic_configuration.events #=> Array
    #   resp.topic_configuration.events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.topic_configuration.event #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.topic_configuration.topic #=> String
    #   resp.queue_configuration.id #=> String
    #   resp.queue_configuration.event #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.queue_configuration.events #=> Array
    #   resp.queue_configuration.events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.queue_configuration.queue #=> String
    #   resp.cloud_function_configuration.id #=> String
    #   resp.cloud_function_configuration.event #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.cloud_function_configuration.events #=> Array
    #   resp.cloud_function_configuration.events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.cloud_function_configuration.cloud_function #=> String
    #   resp.cloud_function_configuration.invocation_role #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketNotification AWS API Documentation
    #
    # @overload get_bucket_notification(params = {})
    # @param [Hash] params ({})
    def get_bucket_notification(params = {}, options = {})
      req = build_request(:get_bucket_notification, params)
      req.send_request(options)
    end

    # Returns the notification configuration of a bucket.
    #
    # If notifications are not enabled on the bucket, the action returns an
    # empty `NotificationConfiguration` element.
    #
    # By default, you must be the bucket owner to read the notification
    # configuration of a bucket. However, the bucket owner can use a bucket
    # policy to grant permission to other users to read this configuration
    # with the `s3:GetBucketNotification` permission.
    #
    # To use this API operation against an access point, provide the alias
    # of the access point in place of the bucket name.
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][1].
    #
    # For more information about setting and reading the notification
    # configuration on a bucket, see [Setting Up Notification of Bucket
    # Events][2]. For more information about bucket policies, see [Using
    # Bucket Policies][3].
    #
    # The following action is related to `GetBucketNotification`:
    #
    # * [PutBucketNotification][4]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketNotification.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the notification
    #   configuration.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::NotificationConfiguration] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::NotificationConfiguration#topic_configurations #topic_configurations} => Array&lt;Types::TopicConfiguration&gt;
    #   * {Types::NotificationConfiguration#queue_configurations #queue_configurations} => Array&lt;Types::QueueConfiguration&gt;
    #   * {Types::NotificationConfiguration#lambda_function_configurations #lambda_function_configurations} => Array&lt;Types::LambdaFunctionConfiguration&gt;
    #   * {Types::NotificationConfiguration#event_bridge_configuration #event_bridge_configuration} => Types::EventBridgeConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_notification_configuration({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.topic_configurations #=> Array
    #   resp.topic_configurations[0].id #=> String
    #   resp.topic_configurations[0].topic_arn #=> String
    #   resp.topic_configurations[0].events #=> Array
    #   resp.topic_configurations[0].events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.topic_configurations[0].filter.key.filter_rules #=> Array
    #   resp.topic_configurations[0].filter.key.filter_rules[0].name #=> String, one of "prefix", "suffix"
    #   resp.topic_configurations[0].filter.key.filter_rules[0].value #=> String
    #   resp.queue_configurations #=> Array
    #   resp.queue_configurations[0].id #=> String
    #   resp.queue_configurations[0].queue_arn #=> String
    #   resp.queue_configurations[0].events #=> Array
    #   resp.queue_configurations[0].events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.queue_configurations[0].filter.key.filter_rules #=> Array
    #   resp.queue_configurations[0].filter.key.filter_rules[0].name #=> String, one of "prefix", "suffix"
    #   resp.queue_configurations[0].filter.key.filter_rules[0].value #=> String
    #   resp.lambda_function_configurations #=> Array
    #   resp.lambda_function_configurations[0].id #=> String
    #   resp.lambda_function_configurations[0].lambda_function_arn #=> String
    #   resp.lambda_function_configurations[0].events #=> Array
    #   resp.lambda_function_configurations[0].events[0] #=> String, one of "s3:ReducedRedundancyLostObject", "s3:ObjectCreated:*", "s3:ObjectCreated:Put", "s3:ObjectCreated:Post", "s3:ObjectCreated:Copy", "s3:ObjectCreated:CompleteMultipartUpload", "s3:ObjectRemoved:*", "s3:ObjectRemoved:Delete", "s3:ObjectRemoved:DeleteMarkerCreated", "s3:ObjectRestore:*", "s3:ObjectRestore:Post", "s3:ObjectRestore:Completed", "s3:Replication:*", "s3:Replication:OperationFailedReplication", "s3:Replication:OperationNotTracked", "s3:Replication:OperationMissedThreshold", "s3:Replication:OperationReplicatedAfterThreshold", "s3:ObjectRestore:Delete", "s3:LifecycleTransition", "s3:IntelligentTiering", "s3:ObjectAcl:Put", "s3:LifecycleExpiration:*", "s3:LifecycleExpiration:Delete", "s3:LifecycleExpiration:DeleteMarkerCreated", "s3:ObjectTagging:*", "s3:ObjectTagging:Put", "s3:ObjectTagging:Delete"
    #   resp.lambda_function_configurations[0].filter.key.filter_rules #=> Array
    #   resp.lambda_function_configurations[0].filter.key.filter_rules[0].name #=> String, one of "prefix", "suffix"
    #   resp.lambda_function_configurations[0].filter.key.filter_rules[0].value #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketNotificationConfiguration AWS API Documentation
    #
    # @overload get_bucket_notification_configuration(params = {})
    # @param [Hash] params ({})
    def get_bucket_notification_configuration(params = {}, options = {})
      req = build_request(:get_bucket_notification_configuration, params)
      req.send_request(options)
    end

    # Retrieves `OwnershipControls` for an Amazon S3 bucket. To use this
    # operation, you must have the `s3:GetBucketOwnershipControls`
    # permission. For more information about Amazon S3 permissions, see
    # [Specifying permissions in a policy][1].
    #
    # For information about Amazon S3 Object Ownership, see [Using Object
    # Ownership][2].
    #
    # The following operations are related to `GetBucketOwnershipControls`:
    #
    # * PutBucketOwnershipControls
    #
    # * DeleteBucketOwnershipControls
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose `OwnershipControls` you want to
    #   retrieve.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketOwnershipControlsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketOwnershipControlsOutput#ownership_controls #ownership_controls} => Types::OwnershipControls
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_ownership_controls({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.ownership_controls.rules #=> Array
    #   resp.ownership_controls.rules[0].object_ownership #=> String, one of "BucketOwnerPreferred", "ObjectWriter", "BucketOwnerEnforced"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketOwnershipControls AWS API Documentation
    #
    # @overload get_bucket_ownership_controls(params = {})
    # @param [Hash] params ({})
    def get_bucket_ownership_controls(params = {}, options = {})
      req = build_request(:get_bucket_ownership_controls, params)
      req.send_request(options)
    end

    # Returns the policy of a specified bucket. If you are using an identity
    # other than the root user of the Amazon Web Services account that owns
    # the bucket, the calling identity must have the `GetBucketPolicy`
    # permissions on the specified bucket and belong to the bucket owner's
    # account in order to use this operation.
    #
    # If you don't have `GetBucketPolicy` permissions, Amazon S3 returns a
    # `403 Access Denied` error. If you have the correct permissions, but
    # you're not using an identity that belongs to the bucket owner's
    # account, Amazon S3 returns a `405 Method Not Allowed` error.
    #
    # To ensure that bucket owners don't inadvertently lock themselves out
    # of their own buckets, the root principal in a bucket owner's Amazon
    # Web Services account can perform the `GetBucketPolicy`,
    # `PutBucketPolicy`, and `DeleteBucketPolicy` API actions, even if their
    # bucket policy explicitly denies the root principal's access. Bucket
    # owner root principals can only be blocked from performing these API
    # actions by VPC endpoint policies and Amazon Web Services Organizations
    # policies.
    #
    # To use this API operation against an access point, provide the alias
    # of the access point in place of the bucket name.
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][1].
    #
    # For more information about bucket policies, see [Using Bucket Policies
    # and User Policies][2].
    #
    # The following action is related to `GetBucketPolicy`:
    #
    # * [GetObject][3]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which to get the bucket policy.
    #
    #   To use this API operation against an access point, provide the alias
    #   of the access point in place of the bucket name.
    #
    #   To use this API operation against an Object Lambda access point,
    #   provide the alias of the Object Lambda access point in place of the
    #   bucket name. If the Object Lambda access point alias in a request is
    #   not valid, the error code `InvalidAccessPointAliasError` is returned.
    #   For more information about `InvalidAccessPointAliasError`, see [List
    #   of Error Codes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketPolicyOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketPolicyOutput#policy #policy} => IO
    #
    #
    # @example Example: To get bucket policy
    #
    #   # The following example returns bucket policy associated with a bucket.
    #
    #   resp = client.get_bucket_policy({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     policy: "{\"Version\":\"2008-10-17\",\"Id\":\"LogPolicy\",\"Statement\":[{\"Sid\":\"Enables the log delivery group to publish logs to your bucket \",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"111122223333\"},\"Action\":[\"s3:GetBucketAcl\",\"s3:GetObjectAcl\",\"s3:PutObject\"],\"Resource\":[\"arn:aws:s3:::policytest1/*\",\"arn:aws:s3:::policytest1\"]}]}", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_policy({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicy AWS API Documentation
    #
    # @overload get_bucket_policy(params = {})
    # @param [Hash] params ({})
    def get_bucket_policy(params = {}, options = {}, &block)
      req = build_request(:get_bucket_policy, params)
      req.send_request(options, &block)
    end

    # Retrieves the policy status for an Amazon S3 bucket, indicating
    # whether the bucket is public. In order to use this operation, you must
    # have the `s3:GetBucketPolicyStatus` permission. For more information
    # about Amazon S3 permissions, see [Specifying Permissions in a
    # Policy][1].
    #
    # For more information about when Amazon S3 considers a bucket public,
    # see [The Meaning of "Public"][2].
    #
    # The following operations are related to `GetBucketPolicyStatus`:
    #
    # * [Using Amazon S3 Block Public Access][3]
    #
    # * [GetPublicAccessBlock][4]
    #
    # * [PutPublicAccessBlock][5]
    #
    # * [DeletePublicAccessBlock][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose policy status you want to
    #   retrieve.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketPolicyStatusOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketPolicyStatusOutput#policy_status #policy_status} => Types::PolicyStatus
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_policy_status({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.policy_status.is_public #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketPolicyStatus AWS API Documentation
    #
    # @overload get_bucket_policy_status(params = {})
    # @param [Hash] params ({})
    def get_bucket_policy_status(params = {}, options = {})
      req = build_request(:get_bucket_policy_status, params)
      req.send_request(options)
    end

    # Returns the replication configuration of a bucket.
    #
    # <note markdown="1"> It can take a while to propagate the put or delete a replication
    # configuration to all Amazon S3 systems. Therefore, a get request soon
    # after put or delete can return a wrong result.
    #
    #  </note>
    #
    # For information about replication configuration, see [Replication][1]
    # in the *Amazon S3 User Guide*.
    #
    # This action requires permissions for the
    # `s3:GetReplicationConfiguration` action. For more information about
    # permissions, see [Using Bucket Policies and User Policies][2].
    #
    # If you include the `Filter` element in a replication configuration,
    # you must also include the `DeleteMarkerReplication` and `Priority`
    # elements. The response also returns those elements.
    #
    # For information about `GetBucketReplication` errors, see [List of
    # replication-related error codes][3]
    #
    # The following operations are related to `GetBucketReplication`:
    #
    # * [PutBucketReplication][4]
    #
    # * [DeleteBucketReplication][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-iam-policies.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ReplicationErrorCodeList
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketReplication.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which to get the replication information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketReplicationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketReplicationOutput#replication_configuration #replication_configuration} => Types::ReplicationConfiguration
    #
    #
    # @example Example: To get replication configuration set on a bucket
    #
    #   # The following example returns replication configuration set on a bucket.
    #
    #   resp = client.get_bucket_replication({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     replication_configuration: {
    #       role: "arn:aws:iam::acct-id:role/example-role", 
    #       rules: [
    #         {
    #           destination: {
    #             bucket: "arn:aws:s3:::destination-bucket", 
    #           }, 
    #           id: "MWIwNTkwZmItMTE3MS00ZTc3LWJkZDEtNzRmODQwYzc1OTQy", 
    #           prefix: "Tax", 
    #           status: "Enabled", 
    #         }, 
    #       ], 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_replication({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.replication_configuration.role #=> String
    #   resp.replication_configuration.rules #=> Array
    #   resp.replication_configuration.rules[0].id #=> String
    #   resp.replication_configuration.rules[0].priority #=> Integer
    #   resp.replication_configuration.rules[0].prefix #=> String
    #   resp.replication_configuration.rules[0].filter.prefix #=> String
    #   resp.replication_configuration.rules[0].filter.tag.key #=> String
    #   resp.replication_configuration.rules[0].filter.tag.value #=> String
    #   resp.replication_configuration.rules[0].filter.and.prefix #=> String
    #   resp.replication_configuration.rules[0].filter.and.tags #=> Array
    #   resp.replication_configuration.rules[0].filter.and.tags[0].key #=> String
    #   resp.replication_configuration.rules[0].filter.and.tags[0].value #=> String
    #   resp.replication_configuration.rules[0].status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].source_selection_criteria.sse_kms_encrypted_objects.status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].source_selection_criteria.replica_modifications.status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].existing_object_replication.status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].destination.bucket #=> String
    #   resp.replication_configuration.rules[0].destination.account #=> String
    #   resp.replication_configuration.rules[0].destination.storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.replication_configuration.rules[0].destination.access_control_translation.owner #=> String, one of "Destination"
    #   resp.replication_configuration.rules[0].destination.encryption_configuration.replica_kms_key_id #=> String
    #   resp.replication_configuration.rules[0].destination.replication_time.status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].destination.replication_time.time.minutes #=> Integer
    #   resp.replication_configuration.rules[0].destination.metrics.status #=> String, one of "Enabled", "Disabled"
    #   resp.replication_configuration.rules[0].destination.metrics.event_threshold.minutes #=> Integer
    #   resp.replication_configuration.rules[0].delete_marker_replication.status #=> String, one of "Enabled", "Disabled"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketReplication AWS API Documentation
    #
    # @overload get_bucket_replication(params = {})
    # @param [Hash] params ({})
    def get_bucket_replication(params = {}, options = {})
      req = build_request(:get_bucket_replication, params)
      req.send_request(options)
    end

    # Returns the request payment configuration of a bucket. To use this
    # version of the operation, you must be the bucket owner. For more
    # information, see [Requester Pays Buckets][1].
    #
    # The following operations are related to `GetBucketRequestPayment`:
    #
    # * [ListObjects][2]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the payment request
    #   configuration
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketRequestPaymentOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketRequestPaymentOutput#payer #payer} => String
    #
    #
    # @example Example: To get bucket versioning configuration
    #
    #   # The following example retrieves bucket versioning configuration.
    #
    #   resp = client.get_bucket_request_payment({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     payer: "BucketOwner", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_request_payment({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.payer #=> String, one of "Requester", "BucketOwner"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketRequestPayment AWS API Documentation
    #
    # @overload get_bucket_request_payment(params = {})
    # @param [Hash] params ({})
    def get_bucket_request_payment(params = {}, options = {})
      req = build_request(:get_bucket_request_payment, params)
      req.send_request(options)
    end

    # Returns the tag set associated with the bucket.
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetBucketTagging` action. By default, the bucket owner has this
    # permission and can grant this permission to others.
    #
    # `GetBucketTagging` has the following special error:
    #
    # * Error code: `NoSuchTagSet`
    #
    #   * Description: There is no tag set associated with the bucket.
    #
    #   ^
    #
    # The following operations are related to `GetBucketTagging`:
    #
    # * [PutBucketTagging][1]
    #
    # * [DeleteBucketTagging][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketTagging.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the tagging information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketTaggingOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketTaggingOutput#tag_set #tag_set} => Array&lt;Types::Tag&gt;
    #
    #
    # @example Example: To get tag set associated with a bucket
    #
    #   # The following example returns tag set associated with a bucket
    #
    #   resp = client.get_bucket_tagging({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tag_set: [
    #       {
    #         key: "key1", 
    #         value: "value1", 
    #       }, 
    #       {
    #         key: "key2", 
    #         value: "value2", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_tagging({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.tag_set #=> Array
    #   resp.tag_set[0].key #=> String
    #   resp.tag_set[0].value #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketTagging AWS API Documentation
    #
    # @overload get_bucket_tagging(params = {})
    # @param [Hash] params ({})
    def get_bucket_tagging(params = {}, options = {})
      req = build_request(:get_bucket_tagging, params)
      req.send_request(options)
    end

    # Returns the versioning state of a bucket.
    #
    # To retrieve the versioning state of a bucket, you must be the bucket
    # owner.
    #
    # This implementation also returns the MFA Delete status of the
    # versioning state. If the MFA Delete status is `enabled`, the bucket
    # owner must use an authentication device to change the versioning state
    # of the bucket.
    #
    # The following operations are related to `GetBucketVersioning`:
    #
    # * [GetObject][1]
    #
    # * [PutObject][2]
    #
    # * [DeleteObject][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to get the versioning information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketVersioningOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketVersioningOutput#status #status} => String
    #   * {Types::GetBucketVersioningOutput#mfa_delete #mfa_delete} => String
    #
    #
    # @example Example: To get bucket versioning configuration
    #
    #   # The following example retrieves bucket versioning configuration.
    #
    #   resp = client.get_bucket_versioning({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     mfa_delete: "Disabled", 
    #     status: "Enabled", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_versioning({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.status #=> String, one of "Enabled", "Suspended"
    #   resp.mfa_delete #=> String, one of "Enabled", "Disabled"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketVersioning AWS API Documentation
    #
    # @overload get_bucket_versioning(params = {})
    # @param [Hash] params ({})
    def get_bucket_versioning(params = {}, options = {})
      req = build_request(:get_bucket_versioning, params)
      req.send_request(options)
    end

    # Returns the website configuration for a bucket. To host website on
    # Amazon S3, you can configure a bucket as website by adding a website
    # configuration. For more information about hosting websites, see
    # [Hosting Websites on Amazon S3][1].
    #
    # This GET action requires the `S3:GetBucketWebsite` permission. By
    # default, only the bucket owner can read the bucket website
    # configuration. However, bucket owners can allow other users to read
    # the website configuration by writing a bucket policy granting them the
    # `S3:GetBucketWebsite` permission.
    #
    # The following operations are related to `GetBucketWebsite`:
    #
    # * [DeleteBucketWebsite][2]
    #
    # * [PutBucketWebsite][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketWebsite.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketWebsite.html
    #
    # @option params [required, String] :bucket
    #   The bucket name for which to get the website configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetBucketWebsiteOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetBucketWebsiteOutput#redirect_all_requests_to #redirect_all_requests_to} => Types::RedirectAllRequestsTo
    #   * {Types::GetBucketWebsiteOutput#index_document #index_document} => Types::IndexDocument
    #   * {Types::GetBucketWebsiteOutput#error_document #error_document} => Types::ErrorDocument
    #   * {Types::GetBucketWebsiteOutput#routing_rules #routing_rules} => Array&lt;Types::RoutingRule&gt;
    #
    #
    # @example Example: To get bucket website configuration
    #
    #   # The following example retrieves website configuration of a bucket.
    #
    #   resp = client.get_bucket_website({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     error_document: {
    #       key: "error.html", 
    #     }, 
    #     index_document: {
    #       suffix: "index.html", 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_bucket_website({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.redirect_all_requests_to.host_name #=> String
    #   resp.redirect_all_requests_to.protocol #=> String, one of "http", "https"
    #   resp.index_document.suffix #=> String
    #   resp.error_document.key #=> String
    #   resp.routing_rules #=> Array
    #   resp.routing_rules[0].condition.http_error_code_returned_equals #=> String
    #   resp.routing_rules[0].condition.key_prefix_equals #=> String
    #   resp.routing_rules[0].redirect.host_name #=> String
    #   resp.routing_rules[0].redirect.http_redirect_code #=> String
    #   resp.routing_rules[0].redirect.protocol #=> String, one of "http", "https"
    #   resp.routing_rules[0].redirect.replace_key_prefix_with #=> String
    #   resp.routing_rules[0].redirect.replace_key_with #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetBucketWebsite AWS API Documentation
    #
    # @overload get_bucket_website(params = {})
    # @param [Hash] params ({})
    def get_bucket_website(params = {}, options = {})
      req = build_request(:get_bucket_website, params)
      req.send_request(options)
    end

    # Retrieves objects from Amazon S3. To use `GET`, you must have `READ`
    # access to the object. If you grant `READ` access to the anonymous
    # user, you can return the object without using an authorization header.
    #
    # An Amazon S3 bucket has no directory hierarchy such as you would find
    # in a typical computer file system. You can, however, create a logical
    # hierarchy by using object key names that imply a folder structure. For
    # example, instead of naming an object `sample.jpg`, you can name it
    # `photos/2006/February/sample.jpg`.
    #
    # To get an object from such a logical hierarchy, specify the full key
    # name for the object in the `GET` operation. For a virtual hosted-style
    # request example, if you have the object
    # `photos/2006/February/sample.jpg`, specify the resource as
    # `/photos/2006/February/sample.jpg`. For a path-style request example,
    # if you have the object `photos/2006/February/sample.jpg` in the bucket
    # named `examplebucket`, specify the resource as
    # `/examplebucket/photos/2006/February/sample.jpg`. For more information
    # about request types, see [HTTP Host Header Bucket Specification][1].
    #
    # For more information about returning the ACL of an object, see
    # [GetObjectAcl][2].
    #
    # If the object you are retrieving is stored in the S3 Glacier Flexible
    # Retrieval or S3 Glacier Deep Archive storage class, or S3
    # Intelligent-Tiering Archive or S3 Intelligent-Tiering Deep Archive
    # tiers, before you can retrieve the object you must first restore a
    # copy using [RestoreObject][3]. Otherwise, this action returns an
    # `InvalidObjectState` error. For information about restoring archived
    # objects, see [Restoring Archived Objects][4].
    #
    # Encryption request headers, like `x-amz-server-side-encryption`,
    # should not be sent for GET requests if your object uses server-side
    # encryption with Key Management Service (KMS) keys (SSE-KMS),
    # dual-layer server-side encryption with Amazon Web Services KMS keys
    # (DSSE-KMS), or server-side encryption with Amazon S3 managed
    # encryption keys (SSE-S3). If your object does use these types of keys,
    # you’ll get an HTTP 400 Bad Request error.
    #
    # If you encrypt an object by using server-side encryption with
    # customer-provided encryption keys (SSE-C) when you store the object in
    # Amazon S3, then when you GET the object, you must use the following
    # headers:
    #
    # * `x-amz-server-side-encryption-customer-algorithm`
    #
    # * `x-amz-server-side-encryption-customer-key`
    #
    # * `x-amz-server-side-encryption-customer-key-MD5`
    #
    # For more information about SSE-C, see [Server-Side Encryption (Using
    # Customer-Provided Encryption Keys)][5].
    #
    # Assuming you have the relevant permission to read object tags, the
    # response also returns the `x-amz-tagging-count` header that provides
    # the count of number of tags associated with the object. You can use
    # [GetObjectTagging][6] to retrieve the tag set associated with an
    # object.
    #
    # Permissions
    #
    # : You need the relevant read object (or version) permission for this
    #   operation. For more information, see [Specifying Permissions in a
    #   Policy][7]. If the object that you request doesn’t exist, the error
    #   that Amazon S3 returns depends on whether you also have the
    #   `s3:ListBucket` permission.
    #
    #   If you have the `s3:ListBucket` permission on the bucket, Amazon S3
    #   returns an HTTP status code 404 (Not Found) error.
    #
    #   If you don’t have the `s3:ListBucket` permission, Amazon S3 returns
    #   an HTTP status code 403 ("access denied") error.
    #
    # Versioning
    #
    # : By default, the `GET` action returns the current version of an
    #   object. To return a different version, use the `versionId`
    #   subresource.
    #
    #   <note markdown="1"> * If you supply a `versionId`, you need the `s3:GetObjectVersion`
    #     permission to access a specific version of an object. If you
    #     request a specific version, you do not need to have the
    #     `s3:GetObject` permission. If you request the current version
    #     without a specific version ID, only `s3:GetObject` permission is
    #     required. `s3:GetObjectVersion` permission won't be required.
    #
    #   * If the current version of the object is a delete marker, Amazon S3
    #     behaves as if the object was deleted and includes
    #     `x-amz-delete-marker: true` in the response.
    #
    #    </note>
    #
    #   For more information about versioning, see [PutBucketVersioning][8].
    #
    # Overriding Response Header Values
    #
    # : There are times when you want to override certain response header
    #   values in a `GET` response. For example, you might override the
    #   `Content-Disposition` response header value in your `GET` request.
    #
    #   You can override values for a set of response headers using the
    #   following query parameters. These response header values are sent
    #   only on a successful request, that is, when status code 200 OK is
    #   returned. The set of headers you can override using these parameters
    #   is a subset of the headers that Amazon S3 accepts when you create an
    #   object. The response headers that you can override for the `GET`
    #   response are `Content-Type`, `Content-Language`, `Expires`,
    #   `Cache-Control`, `Content-Disposition`, and `Content-Encoding`. To
    #   override these header values in the `GET` response, you use the
    #   following request parameters.
    #
    #   <note markdown="1"> You must sign the request, either using an Authorization header or a
    #   presigned URL, when using these parameters. They cannot be used with
    #   an unsigned (anonymous) request.
    #
    #    </note>
    #
    #   * `response-content-type`
    #
    #   * `response-content-language`
    #
    #   * `response-expires`
    #
    #   * `response-cache-control`
    #
    #   * `response-content-disposition`
    #
    #   * `response-content-encoding`
    #
    # Overriding Response Header Values
    #
    # : If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows: `If-Match` condition evaluates to
    #   `true`, and; `If-Unmodified-Since` condition evaluates to `false`;
    #   then, S3 returns 200 OK and the data requested.
    #
    #   If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows:` If-None-Match` condition
    #   evaluates to `false`, and; `If-Modified-Since` condition evaluates
    #   to `true`; then, S3 returns 304 Not Modified response code.
    #
    #   For more information about conditional requests, see [RFC 7232][9].
    #
    # The following operations are related to `GetObject`:
    #
    # * [ListBuckets][10]
    #
    # * [GetObjectAcl][2]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html#VirtualHostingSpecifyBucket
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketVersioning.html
    # [9]: https://tools.ietf.org/html/rfc7232
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html
    #
    # @option params [String, IO] :response_target
    #   Where to write response data, file path, or IO object.
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When using an Object Lambda access point the hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-object-lambda.*Region*.amazonaws.com.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :if_match
    #   Return the object only if its entity tag (ETag) is the same as the one
    #   specified; otherwise, return a 412 (precondition failed) error.
    #
    # @option params [Time,DateTime,Date,Integer,String] :if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time; otherwise, return a 304 (not modified) error.
    #
    # @option params [String] :if_none_match
    #   Return the object only if its entity tag (ETag) is different from the
    #   one specified; otherwise, return a 304 (not modified) error.
    #
    # @option params [Time,DateTime,Date,Integer,String] :if_unmodified_since
    #   Return the object only if it has not been modified since the specified
    #   time; otherwise, return a 412 (precondition failed) error.
    #
    # @option params [required, String] :key
    #   Key of the object to get.
    #
    # @option params [String] :range
    #   Downloads the specified range bytes of an object. For more information
    #   about the HTTP Range header, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-range][1].
    #
    #   <note markdown="1"> Amazon S3 doesn't support retrieving multiple ranges of data per
    #   `GET` request.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-range
    #
    # @option params [String] :response_cache_control
    #   Sets the `Cache-Control` header of the response.
    #
    # @option params [String] :response_content_disposition
    #   Sets the `Content-Disposition` header of the response
    #
    # @option params [String] :response_content_encoding
    #   Sets the `Content-Encoding` header of the response.
    #
    # @option params [String] :response_content_language
    #   Sets the `Content-Language` header of the response.
    #
    # @option params [String] :response_content_type
    #   Sets the `Content-Type` header of the response.
    #
    # @option params [Time,DateTime,Date,Integer,String] :response_expires
    #   Sets the `Expires` header of the response.
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when decrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 used to
    #   encrypt the data. This value is used to decrypt the object when
    #   recovering it and must match the one used when storing the data. The
    #   key must be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [Integer] :part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' GET request
    #   for the part specified. Useful for downloading just a part of an
    #   object.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :checksum_mode
    #   To retrieve the checksum, this mode must be enabled.
    #
    # @return [Types::GetObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectOutput#body #body} => IO
    #   * {Types::GetObjectOutput#delete_marker #delete_marker} => Boolean
    #   * {Types::GetObjectOutput#accept_ranges #accept_ranges} => String
    #   * {Types::GetObjectOutput#expiration #expiration} => String
    #   * {Types::GetObjectOutput#restore #restore} => String
    #   * {Types::GetObjectOutput#last_modified #last_modified} => Time
    #   * {Types::GetObjectOutput#content_length #content_length} => Integer
    #   * {Types::GetObjectOutput#etag #etag} => String
    #   * {Types::GetObjectOutput#checksum_crc32 #checksum_crc32} => String
    #   * {Types::GetObjectOutput#checksum_crc32c #checksum_crc32c} => String
    #   * {Types::GetObjectOutput#checksum_sha1 #checksum_sha1} => String
    #   * {Types::GetObjectOutput#checksum_sha256 #checksum_sha256} => String
    #   * {Types::GetObjectOutput#missing_meta #missing_meta} => Integer
    #   * {Types::GetObjectOutput#version_id #version_id} => String
    #   * {Types::GetObjectOutput#cache_control #cache_control} => String
    #   * {Types::GetObjectOutput#content_disposition #content_disposition} => String
    #   * {Types::GetObjectOutput#content_encoding #content_encoding} => String
    #   * {Types::GetObjectOutput#content_language #content_language} => String
    #   * {Types::GetObjectOutput#content_range #content_range} => String
    #   * {Types::GetObjectOutput#content_type #content_type} => String
    #   * {Types::GetObjectOutput#expires #expires} => Time
    #   * {Types::GetObjectOutput#expires_string #expires_string} => String
    #   * {Types::GetObjectOutput#website_redirect_location #website_redirect_location} => String
    #   * {Types::GetObjectOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::GetObjectOutput#metadata #metadata} => Hash&lt;String,String&gt;
    #   * {Types::GetObjectOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::GetObjectOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::GetObjectOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::GetObjectOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::GetObjectOutput#storage_class #storage_class} => String
    #   * {Types::GetObjectOutput#request_charged #request_charged} => String
    #   * {Types::GetObjectOutput#replication_status #replication_status} => String
    #   * {Types::GetObjectOutput#parts_count #parts_count} => Integer
    #   * {Types::GetObjectOutput#tag_count #tag_count} => Integer
    #   * {Types::GetObjectOutput#object_lock_mode #object_lock_mode} => String
    #   * {Types::GetObjectOutput#object_lock_retain_until_date #object_lock_retain_until_date} => Time
    #   * {Types::GetObjectOutput#object_lock_legal_hold_status #object_lock_legal_hold_status} => String
    #
    #
    # @example Example: To retrieve a byte range of an object 
    #
    #   # The following example retrieves an object for an S3 bucket. The request specifies the range header to retrieve a
    #   # specific byte range.
    #
    #   resp = client.get_object({
    #     bucket: "examplebucket", 
    #     key: "SampleFile.txt", 
    #     range: "bytes=0-9", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     accept_ranges: "bytes", 
    #     content_length: 10, 
    #     content_range: "bytes 0-9/43", 
    #     content_type: "text/plain", 
    #     etag: "\"0d94420ffd0bc68cd3d152506b97a9cc\"", 
    #     last_modified: Time.parse("Thu, 09 Oct 2014 22:57:28 GMT"), 
    #     metadata: {
    #     }, 
    #     version_id: "null", 
    #   }
    #
    # @example Example: To retrieve an object
    #
    #   # The following example retrieves an object for an S3 bucket.
    #
    #   resp = client.get_object({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     accept_ranges: "bytes", 
    #     content_length: 3191, 
    #     content_type: "image/jpeg", 
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     last_modified: Time.parse("Thu, 15 Dec 2016 01:19:41 GMT"), 
    #     metadata: {
    #     }, 
    #     tag_count: 2, 
    #     version_id: "null", 
    #   }
    #
    # @example Download an object to disk
    #   # stream object directly to disk
    #   resp = s3.get_object(
    #     response_target: '/path/to/file',
    #     bucket: 'bucket-name',
    #     key: 'object-key')
    #
    #   # you can still access other response data
    #   resp.metadata #=> { ... }
    #   resp.etag #=> "..."
    #
    # @example Download object into memory
    #   # omit :response_target to download to a StringIO in memory
    #   resp = s3.get_object(bucket: 'bucket-name', key: 'object-key')
    #
    #   # call #read or #string on the response body
    #   resp.body.read
    #   #=> '...'
    #
    # @example Streaming data to a block
    #   # WARNING: yielding data to a block disables retries of networking errors
    #   # However truncation of the body will be retried automatically using a range request
    #   File.open('/path/to/file', 'wb') do |file|
    #     s3.get_object(bucket: 'bucket-name', key: 'object-key') do |chunk, headers|
    #       # headers['content-length']
    #       file.write(chunk)
    #     end
    #   end
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object({
    #     bucket: "BucketName", # required
    #     if_match: "IfMatch",
    #     if_modified_since: Time.now,
    #     if_none_match: "IfNoneMatch",
    #     if_unmodified_since: Time.now,
    #     key: "ObjectKey", # required
    #     range: "Range",
    #     response_cache_control: "ResponseCacheControl",
    #     response_content_disposition: "ResponseContentDisposition",
    #     response_content_encoding: "ResponseContentEncoding",
    #     response_content_language: "ResponseContentLanguage",
    #     response_content_type: "ResponseContentType",
    #     response_expires: Time.now,
    #     version_id: "ObjectVersionId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     part_number: 1,
    #     expected_bucket_owner: "AccountId",
    #     checksum_mode: "ENABLED", # accepts ENABLED
    #   })
    #
    # @example Response structure
    #
    #   resp.body #=> IO
    #   resp.delete_marker #=> Boolean
    #   resp.accept_ranges #=> String
    #   resp.expiration #=> String
    #   resp.restore #=> String
    #   resp.last_modified #=> Time
    #   resp.content_length #=> Integer
    #   resp.etag #=> String
    #   resp.checksum_crc32 #=> String
    #   resp.checksum_crc32c #=> String
    #   resp.checksum_sha1 #=> String
    #   resp.checksum_sha256 #=> String
    #   resp.missing_meta #=> Integer
    #   resp.version_id #=> String
    #   resp.cache_control #=> String
    #   resp.content_disposition #=> String
    #   resp.content_encoding #=> String
    #   resp.content_language #=> String
    #   resp.content_range #=> String
    #   resp.content_type #=> String
    #   resp.expires #=> Time
    #   resp.expires_string #=> String
    #   resp.website_redirect_location #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.metadata #=> Hash
    #   resp.metadata["MetadataKey"] #=> String
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.request_charged #=> String, one of "requester"
    #   resp.replication_status #=> String, one of "COMPLETE", "PENDING", "FAILED", "REPLICA"
    #   resp.parts_count #=> Integer
    #   resp.tag_count #=> Integer
    #   resp.object_lock_mode #=> String, one of "GOVERNANCE", "COMPLIANCE"
    #   resp.object_lock_retain_until_date #=> Time
    #   resp.object_lock_legal_hold_status #=> String, one of "ON", "OFF"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObject AWS API Documentation
    #
    # @overload get_object(params = {})
    # @param [Hash] params ({})
    def get_object(params = {}, options = {}, &block)
      req = build_request(:get_object, params)
      req.send_request(options, &block)
    end

    # Returns the access control list (ACL) of an object. To use this
    # operation, you must have `s3:GetObjectAcl` permissions or `READ_ACP`
    # access to the object. For more information, see [Mapping of ACL
    # permissions and access policy permissions][1] in the *Amazon S3 User
    # Guide*
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # By default, GET returns ACL information about the current version of
    # an object. To return ACL information about a different version, use
    # the versionId subresource.
    #
    # <note markdown="1"> If your bucket uses the bucket owner enforced setting for S3 Object
    # Ownership, requests to read ACLs are still supported and return the
    # `bucket-owner-full-control` ACL with the owner being the account that
    # created the bucket. For more information, see [ Controlling object
    # ownership and disabling ACLs][2] in the *Amazon S3 User Guide*.
    #
    #  </note>
    #
    # The following operations are related to `GetObjectAcl`:
    #
    # * [GetObject][3]
    #
    # * [GetObjectAttributes][4]
    #
    # * [DeleteObject][5]
    #
    # * [PutObject][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#acl-access-policy-permission-mapping
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    #
    # @option params [required, String] :bucket
    #   The bucket name that contains the object for which to get the ACL
    #   information.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [required, String] :key
    #   The key of the object for which to get the ACL information.
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetObjectAclOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectAclOutput#owner #owner} => Types::Owner
    #   * {Types::GetObjectAclOutput#grants #grants} => Array&lt;Types::Grant&gt;
    #   * {Types::GetObjectAclOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To retrieve object ACL
    #
    #   # The following example retrieves access control list (ACL) of an object.
    #
    #   resp = client.get_object_acl({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     grants: [
    #       {
    #         grantee: {
    #           display_name: "owner-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #           type: "CanonicalUser", 
    #         }, 
    #         permission: "WRITE", 
    #       }, 
    #       {
    #         grantee: {
    #           display_name: "owner-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #           type: "CanonicalUser", 
    #         }, 
    #         permission: "WRITE_ACP", 
    #       }, 
    #       {
    #         grantee: {
    #           display_name: "owner-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #           type: "CanonicalUser", 
    #         }, 
    #         permission: "READ", 
    #       }, 
    #       {
    #         grantee: {
    #           display_name: "owner-display-name", 
    #           id: "852b113eexamplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #           type: "CanonicalUser", 
    #         }, 
    #         permission: "READ_ACP", 
    #       }, 
    #     ], 
    #     owner: {
    #       display_name: "owner-display-name", 
    #       id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_acl({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.owner.display_name #=> String
    #   resp.owner.id #=> String
    #   resp.grants #=> Array
    #   resp.grants[0].grantee.display_name #=> String
    #   resp.grants[0].grantee.email_address #=> String
    #   resp.grants[0].grantee.id #=> String
    #   resp.grants[0].grantee.type #=> String, one of "CanonicalUser", "AmazonCustomerByEmail", "Group"
    #   resp.grants[0].grantee.uri #=> String
    #   resp.grants[0].permission #=> String, one of "FULL_CONTROL", "WRITE", "WRITE_ACP", "READ", "READ_ACP"
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAcl AWS API Documentation
    #
    # @overload get_object_acl(params = {})
    # @param [Hash] params ({})
    def get_object_acl(params = {}, options = {})
      req = build_request(:get_object_acl, params)
      req.send_request(options)
    end

    # Retrieves all the metadata from an object without returning the object
    # itself. This action is useful if you're interested only in an
    # object's metadata. To use `GetObjectAttributes`, you must have READ
    # access to the object.
    #
    # `GetObjectAttributes` combines the functionality of `HeadObject` and
    # `ListParts`. All of the data returned with each of those individual
    # calls can be returned with a single call to `GetObjectAttributes`.
    #
    # If you encrypt an object by using server-side encryption with
    # customer-provided encryption keys (SSE-C) when you store the object in
    # Amazon S3, then when you retrieve the metadata from the object, you
    # must use the following headers:
    #
    # * `x-amz-server-side-encryption-customer-algorithm`
    #
    # * `x-amz-server-side-encryption-customer-key`
    #
    # * `x-amz-server-side-encryption-customer-key-MD5`
    #
    # For more information about SSE-C, see [Server-Side Encryption (Using
    # Customer-Provided Encryption Keys)][1] in the *Amazon S3 User Guide*.
    #
    # <note markdown="1"> * Encryption request headers, such as `x-amz-server-side-encryption`,
    #   should not be sent for GET requests if your object uses server-side
    #   encryption with Amazon Web Services KMS keys stored in Amazon Web
    #   Services Key Management Service (SSE-KMS) or server-side encryption
    #   with Amazon S3 managed keys (SSE-S3). If your object does use these
    #   types of keys, you'll get an HTTP `400 Bad Request` error.
    #
    # * The last modified property in this case is the creation date of the
    #   object.
    #
    #  </note>
    #
    # Consider the following when using request headers:
    #
    # * If both of the `If-Match` and `If-Unmodified-Since` headers are
    #   present in the request as follows, then Amazon S3 returns the HTTP
    #   status code `200 OK` and the data requested:
    #
    #   * `If-Match` condition evaluates to `true`.
    #
    #   * `If-Unmodified-Since` condition evaluates to `false`.
    #
    # * If both of the `If-None-Match` and `If-Modified-Since` headers are
    #   present in the request as follows, then Amazon S3 returns the HTTP
    #   status code `304 Not Modified`:
    #
    #   * `If-None-Match` condition evaluates to `false`.
    #
    #   * `If-Modified-Since` condition evaluates to `true`.
    #
    # For more information about conditional requests, see [RFC 7232][2].
    #
    # Permissions
    #
    # : The permissions that you need to use this operation depend on
    #   whether the bucket is versioned. If the bucket is versioned, you
    #   need both the `s3:GetObjectVersion` and
    #   `s3:GetObjectVersionAttributes` permissions for this operation. If
    #   the bucket is not versioned, you need the `s3:GetObject` and
    #   `s3:GetObjectAttributes` permissions. For more information, see
    #   [Specifying Permissions in a Policy][3] in the *Amazon S3 User
    #   Guide*. If the object that you request does not exist, the error
    #   Amazon S3 returns depends on whether you also have the
    #   `s3:ListBucket` permission.
    #
    #   * If you have the `s3:ListBucket` permission on the bucket, Amazon
    #     S3 returns an HTTP status code `404 Not Found` ("no such key")
    #     error.
    #
    #   * If you don't have the `s3:ListBucket` permission, Amazon S3
    #     returns an HTTP status code `403 Forbidden` ("access denied")
    #     error.
    #
    # The following actions are related to `GetObjectAttributes`:
    #
    # * [GetObject][4]
    #
    # * [GetObjectAcl][5]
    #
    # * [GetObjectLegalHold][6]
    #
    # * [GetObjectLockConfiguration][7]
    #
    # * [GetObjectRetention][8]
    #
    # * [GetObjectTagging][9]
    #
    # * [HeadObject][10]
    #
    # * [ListParts][11]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # [2]: https://tools.ietf.org/html/rfc7232
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLegalHold.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectLockConfiguration.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectRetention.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket that contains the object.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   The object key.
    #
    # @option params [String] :version_id
    #   The version ID used to reference a specific version of the object.
    #
    # @option params [Integer] :max_parts
    #   Sets the maximum number of parts to return.
    #
    # @option params [Integer] :part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [required, Array<String>] :object_attributes
    #   An XML header that specifies the fields at the root level that you
    #   want returned in the response. Fields that you do not specify are not
    #   returned.
    #
    # @return [Types::GetObjectAttributesOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectAttributesOutput#delete_marker #delete_marker} => Boolean
    #   * {Types::GetObjectAttributesOutput#last_modified #last_modified} => Time
    #   * {Types::GetObjectAttributesOutput#version_id #version_id} => String
    #   * {Types::GetObjectAttributesOutput#request_charged #request_charged} => String
    #   * {Types::GetObjectAttributesOutput#etag #etag} => String
    #   * {Types::GetObjectAttributesOutput#checksum #checksum} => Types::Checksum
    #   * {Types::GetObjectAttributesOutput#object_parts #object_parts} => Types::GetObjectAttributesParts
    #   * {Types::GetObjectAttributesOutput#storage_class #storage_class} => String
    #   * {Types::GetObjectAttributesOutput#object_size #object_size} => Integer
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_attributes({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     max_parts: 1,
    #     part_number_marker: 1,
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     object_attributes: ["ETag"], # required, accepts ETag, Checksum, ObjectParts, StorageClass, ObjectSize
    #   })
    #
    # @example Response structure
    #
    #   resp.delete_marker #=> Boolean
    #   resp.last_modified #=> Time
    #   resp.version_id #=> String
    #   resp.request_charged #=> String, one of "requester"
    #   resp.etag #=> String
    #   resp.checksum.checksum_crc32 #=> String
    #   resp.checksum.checksum_crc32c #=> String
    #   resp.checksum.checksum_sha1 #=> String
    #   resp.checksum.checksum_sha256 #=> String
    #   resp.object_parts.total_parts_count #=> Integer
    #   resp.object_parts.part_number_marker #=> Integer
    #   resp.object_parts.next_part_number_marker #=> Integer
    #   resp.object_parts.max_parts #=> Integer
    #   resp.object_parts.is_truncated #=> Boolean
    #   resp.object_parts.parts #=> Array
    #   resp.object_parts.parts[0].part_number #=> Integer
    #   resp.object_parts.parts[0].size #=> Integer
    #   resp.object_parts.parts[0].checksum_crc32 #=> String
    #   resp.object_parts.parts[0].checksum_crc32c #=> String
    #   resp.object_parts.parts[0].checksum_sha1 #=> String
    #   resp.object_parts.parts[0].checksum_sha256 #=> String
    #   resp.storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.object_size #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectAttributes AWS API Documentation
    #
    # @overload get_object_attributes(params = {})
    # @param [Hash] params ({})
    def get_object_attributes(params = {}, options = {})
      req = build_request(:get_object_attributes, params)
      req.send_request(options)
    end

    # Gets an object's current legal hold status. For more information, see
    # [Locking Objects][1].
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # The following action is related to `GetObjectLegalHold`:
    #
    # * [GetObjectAttributes][2]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object whose legal hold status you want
    #   to retrieve.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [required, String] :key
    #   The key name for the object whose legal hold status you want to
    #   retrieve.
    #
    # @option params [String] :version_id
    #   The version ID of the object whose legal hold status you want to
    #   retrieve.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetObjectLegalHoldOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectLegalHoldOutput#legal_hold #legal_hold} => Types::ObjectLockLegalHold
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_legal_hold({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.legal_hold.status #=> String, one of "ON", "OFF"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLegalHold AWS API Documentation
    #
    # @overload get_object_legal_hold(params = {})
    # @param [Hash] params ({})
    def get_object_legal_hold(params = {}, options = {})
      req = build_request(:get_object_legal_hold, params)
      req.send_request(options)
    end

    # Gets the Object Lock configuration for a bucket. The rule specified in
    # the Object Lock configuration will be applied by default to every new
    # object placed in the specified bucket. For more information, see
    # [Locking Objects][1].
    #
    # The following action is related to `GetObjectLockConfiguration`:
    #
    # * [GetObjectAttributes][2]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    #
    # @option params [required, String] :bucket
    #   The bucket whose Object Lock configuration you want to retrieve.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetObjectLockConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectLockConfigurationOutput#object_lock_configuration #object_lock_configuration} => Types::ObjectLockConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_lock_configuration({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.object_lock_configuration.object_lock_enabled #=> String, one of "Enabled"
    #   resp.object_lock_configuration.rule.default_retention.mode #=> String, one of "GOVERNANCE", "COMPLIANCE"
    #   resp.object_lock_configuration.rule.default_retention.days #=> Integer
    #   resp.object_lock_configuration.rule.default_retention.years #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectLockConfiguration AWS API Documentation
    #
    # @overload get_object_lock_configuration(params = {})
    # @param [Hash] params ({})
    def get_object_lock_configuration(params = {}, options = {})
      req = build_request(:get_object_lock_configuration, params)
      req.send_request(options)
    end

    # Retrieves an object's retention settings. For more information, see
    # [Locking Objects][1].
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # The following action is related to `GetObjectRetention`:
    #
    # * [GetObjectAttributes][2]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object whose retention settings you
    #   want to retrieve.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [required, String] :key
    #   The key name for the object whose retention settings you want to
    #   retrieve.
    #
    # @option params [String] :version_id
    #   The version ID for the object whose retention settings you want to
    #   retrieve.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetObjectRetentionOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectRetentionOutput#retention #retention} => Types::ObjectLockRetention
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_retention({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.retention.mode #=> String, one of "GOVERNANCE", "COMPLIANCE"
    #   resp.retention.retain_until_date #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectRetention AWS API Documentation
    #
    # @overload get_object_retention(params = {})
    # @param [Hash] params ({})
    def get_object_retention(params = {}, options = {})
      req = build_request(:get_object_retention, params)
      req.send_request(options)
    end

    # Returns the tag-set of an object. You send the GET request against the
    # tagging subresource associated with the object.
    #
    # To use this operation, you must have permission to perform the
    # `s3:GetObjectTagging` action. By default, the GET action returns
    # information about current version of an object. For a versioned
    # bucket, you can have multiple versions of an object in your bucket. To
    # retrieve tags of any other version, use the versionId query parameter.
    # You also need permission for the `s3:GetObjectVersionTagging` action.
    #
    # By default, the bucket owner has this permission and can grant this
    # permission to others.
    #
    # For information about the Amazon S3 object tagging feature, see
    # [Object Tagging][1].
    #
    # The following actions are related to `GetObjectTagging`:
    #
    # * [DeleteObjectTagging][2]
    #
    # * [GetObjectAttributes][3]
    #
    # * [PutObjectTagging][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObjectTagging.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object for which to get the tagging
    #   information.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Object key for which to get the tagging information.
    #
    # @option params [String] :version_id
    #   The versionId of the object for which to get the tagging information.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @return [Types::GetObjectTaggingOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectTaggingOutput#version_id #version_id} => String
    #   * {Types::GetObjectTaggingOutput#tag_set #tag_set} => Array&lt;Types::Tag&gt;
    #
    #
    # @example Example: To retrieve tag set of an object
    #
    #   # The following example retrieves tag set of an object.
    #
    #   resp = client.get_object_tagging({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tag_set: [
    #       {
    #         key: "Key4", 
    #         value: "Value4", 
    #       }, 
    #       {
    #         key: "Key3", 
    #         value: "Value3", 
    #       }, 
    #     ], 
    #     version_id: "null", 
    #   }
    #
    # @example Example: To retrieve tag set of a specific object version
    #
    #   # The following example retrieves tag set of an object. The request specifies object version.
    #
    #   resp = client.get_object_tagging({
    #     bucket: "examplebucket", 
    #     key: "exampleobject", 
    #     version_id: "ydlaNkwWm0SfKJR.T1b1fIdPRbldTYRI", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     tag_set: [
    #       {
    #         key: "Key1", 
    #         value: "Value1", 
    #       }, 
    #     ], 
    #     version_id: "ydlaNkwWm0SfKJR.T1b1fIdPRbldTYRI", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_tagging({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     expected_bucket_owner: "AccountId",
    #     request_payer: "requester", # accepts requester
    #   })
    #
    # @example Response structure
    #
    #   resp.version_id #=> String
    #   resp.tag_set #=> Array
    #   resp.tag_set[0].key #=> String
    #   resp.tag_set[0].value #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTagging AWS API Documentation
    #
    # @overload get_object_tagging(params = {})
    # @param [Hash] params ({})
    def get_object_tagging(params = {}, options = {})
      req = build_request(:get_object_tagging, params)
      req.send_request(options)
    end

    # Returns torrent files from a bucket. BitTorrent can save you bandwidth
    # when you're distributing large files.
    #
    # <note markdown="1"> You can get torrent only for objects that are less than 5 GB in size,
    # and that are not encrypted using server-side encryption with a
    # customer-provided encryption key.
    #
    #  </note>
    #
    # To use GET, you must have READ access to the object.
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # The following action is related to `GetObjectTorrent`:
    #
    # * [GetObject][1]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    #
    # @option params [String, IO] :response_target
    #   Where to write response data, file path, or IO object.
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the object for which to get the
    #   torrent files.
    #
    # @option params [required, String] :key
    #   The object key for which to get the information.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetObjectTorrentOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetObjectTorrentOutput#body #body} => IO
    #   * {Types::GetObjectTorrentOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To retrieve torrent files for an object
    #
    #   # The following example retrieves torrent files of an object.
    #
    #   resp = client.get_object_torrent({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_object_torrent({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.body #=> IO
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetObjectTorrent AWS API Documentation
    #
    # @overload get_object_torrent(params = {})
    # @param [Hash] params ({})
    def get_object_torrent(params = {}, options = {}, &block)
      req = build_request(:get_object_torrent, params)
      req.send_request(options, &block)
    end

    # Retrieves the `PublicAccessBlock` configuration for an Amazon S3
    # bucket. To use this operation, you must have the
    # `s3:GetBucketPublicAccessBlock` permission. For more information about
    # Amazon S3 permissions, see [Specifying Permissions in a Policy][1].
    #
    # When Amazon S3 evaluates the `PublicAccessBlock` configuration for a
    # bucket or an object, it checks the `PublicAccessBlock` configuration
    # for both the bucket (or the bucket that contains the object) and the
    # bucket owner's account. If the `PublicAccessBlock` settings are
    # different between the bucket and the account, Amazon S3 uses the most
    # restrictive combination of the bucket-level and account-level
    # settings.
    #
    # For more information about when Amazon S3 considers a bucket or an
    # object public, see [The Meaning of "Public"][2].
    #
    # The following operations are related to `GetPublicAccessBlock`:
    #
    # * [Using Amazon S3 Block Public Access][3]
    #
    # * [PutPublicAccessBlock][4]
    #
    # * [GetPublicAccessBlock][5]
    #
    # * [DeletePublicAccessBlock][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutPublicAccessBlock.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to retrieve.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::GetPublicAccessBlockOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetPublicAccessBlockOutput#public_access_block_configuration #public_access_block_configuration} => Types::PublicAccessBlockConfiguration
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_public_access_block({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.public_access_block_configuration.block_public_acls #=> Boolean
    #   resp.public_access_block_configuration.ignore_public_acls #=> Boolean
    #   resp.public_access_block_configuration.block_public_policy #=> Boolean
    #   resp.public_access_block_configuration.restrict_public_buckets #=> Boolean
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/GetPublicAccessBlock AWS API Documentation
    #
    # @overload get_public_access_block(params = {})
    # @param [Hash] params ({})
    def get_public_access_block(params = {}, options = {})
      req = build_request(:get_public_access_block, params)
      req.send_request(options)
    end

    # This action is useful to determine if a bucket exists and you have
    # permission to access it. The action returns a `200 OK` if the bucket
    # exists and you have permission to access it.
    #
    # If the bucket does not exist or you do not have permission to access
    # it, the `HEAD` request returns a generic `400 Bad Request`, `403
    # Forbidden` or `404 Not Found` code. A message body is not included, so
    # you cannot determine the exception beyond these error codes.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:ListBucket` action. The bucket owner has this permission by
    # default and can grant this permission to others. For more information
    # about permissions, see [Permissions Related to Bucket Subresource
    # Operations][1] and [Managing Access Permissions to Your Amazon S3
    # Resources][2].
    #
    # To use this API operation against an access point, you must provide
    # the alias of the access point in place of the bucket name or specify
    # the access point ARN. When using the access point ARN, you must direct
    # requests to the access point hostname. The access point hostname takes
    # the form
    # *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    # When using the Amazon Web Services SDKs, you provide the ARN in place
    # of the bucket name. For more information, see [Using access
    # points][3].
    #
    # To use this API operation against an Object Lambda access point,
    # provide the alias of the Object Lambda access point in place of the
    # bucket name. If the Object Lambda access point alias in a request is
    # not valid, the error code `InvalidAccessPointAliasError` is returned.
    # For more information about `InvalidAccessPointAliasError`, see [List
    # of Error Codes][4].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with an Object Lambda access point, provide
    #   the alias of the Object Lambda access point in place of the bucket
    #   name. If the Object Lambda access point alias in a request is not
    #   valid, the error code `InvalidAccessPointAliasError` is returned. For
    #   more information about `InvalidAccessPointAliasError`, see [List of
    #   Error Codes][2].
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][3] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ErrorCodeList
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To determine if bucket exists
    #
    #   # This operation checks to see if a bucket exists.
    #
    #   resp = client.head_bucket({
    #     bucket: "acl1", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.head_bucket({
    #     bucket: "BucketName", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    #
    # The following waiters are defined for this operation (see {Client#wait_until} for detailed usage):
    #
    #   * bucket_exists
    #   * bucket_not_exists
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadBucket AWS API Documentation
    #
    # @overload head_bucket(params = {})
    # @param [Hash] params ({})
    def head_bucket(params = {}, options = {})
      req = build_request(:head_bucket, params)
      req.send_request(options)
    end

    # The `HEAD` action retrieves metadata from an object without returning
    # the object itself. This action is useful if you're only interested in
    # an object's metadata. To use `HEAD`, you must have READ access to the
    # object.
    #
    # A `HEAD` request has the same options as a `GET` action on an object.
    # The response is identical to the `GET` response except that there is
    # no response body. Because of this, if the `HEAD` request generates an
    # error, it returns a generic `400 Bad Request`, `403 Forbidden` or `404
    # Not Found` code. It is not possible to retrieve the exact exception
    # beyond these error codes.
    #
    # If you encrypt an object by using server-side encryption with
    # customer-provided encryption keys (SSE-C) when you store the object in
    # Amazon S3, then when you retrieve the metadata from the object, you
    # must use the following headers:
    #
    # * `x-amz-server-side-encryption-customer-algorithm`
    #
    # * `x-amz-server-side-encryption-customer-key`
    #
    # * `x-amz-server-side-encryption-customer-key-MD5`
    #
    # For more information about SSE-C, see [Server-Side Encryption (Using
    # Customer-Provided Encryption Keys)][1].
    #
    # <note markdown="1"> * Encryption request headers, like `x-amz-server-side-encryption`,
    #   should not be sent for `GET` requests if your object uses
    #   server-side encryption with Key Management Service (KMS) keys
    #   (SSE-KMS), dual-layer server-side encryption with Amazon Web
    #   Services KMS keys (DSSE-KMS), or server-side encryption with Amazon
    #   S3 managed encryption keys (SSE-S3). If your object does use these
    #   types of keys, you’ll get an HTTP 400 Bad Request error.
    #
    # * The last modified property in this case is the creation date of the
    #   object.
    #
    #  </note>
    #
    # Request headers are limited to 8 KB in size. For more information, see
    # [Common Request Headers][2].
    #
    # Consider the following when using request headers:
    #
    # * Consideration 1 – If both of the `If-Match` and
    #   `If-Unmodified-Since` headers are present in the request as follows:
    #
    #   * `If-Match` condition evaluates to `true`, and;
    #
    #   * `If-Unmodified-Since` condition evaluates to `false`;
    #
    #   Then Amazon S3 returns `200 OK` and the data requested.
    #
    # * Consideration 2 – If both of the `If-None-Match` and
    #   `If-Modified-Since` headers are present in the request as follows:
    #
    #   * `If-None-Match` condition evaluates to `false`, and;
    #
    #   * `If-Modified-Since` condition evaluates to `true`;
    #
    #   Then Amazon S3 returns the `304 Not Modified` response code.
    #
    # For more information about conditional requests, see [RFC 7232][3].
    #
    # Permissions
    #
    # : You need the relevant read object (or version) permission for this
    #   operation. For more information, see [Actions, resources, and
    #   condition keys for Amazon S3][4]. If the object you request doesn't
    #   exist, the error that Amazon S3 returns depends on whether you also
    #   have the s3:ListBucket permission.
    #
    #   * If you have the `s3:ListBucket` permission on the bucket, Amazon
    #     S3 returns an HTTP status code 404 error.
    #
    #   * If you don’t have the `s3:ListBucket` permission, Amazon S3
    #     returns an HTTP status code 403 error.
    #
    # The following actions are related to `HeadObject`:
    #
    # * [GetObject][5]
    #
    # * [GetObjectAttributes][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html
    # [3]: https://tools.ietf.org/html/rfc7232
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/list_amazons3.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the object.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :if_match
    #   Return the object only if its entity tag (ETag) is the same as the one
    #   specified; otherwise, return a 412 (precondition failed) error.
    #
    # @option params [Time,DateTime,Date,Integer,String] :if_modified_since
    #   Return the object only if it has been modified since the specified
    #   time; otherwise, return a 304 (not modified) error.
    #
    # @option params [String] :if_none_match
    #   Return the object only if its entity tag (ETag) is different from the
    #   one specified; otherwise, return a 304 (not modified) error.
    #
    # @option params [Time,DateTime,Date,Integer,String] :if_unmodified_since
    #   Return the object only if it has not been modified since the specified
    #   time; otherwise, return a 412 (precondition failed) error.
    #
    # @option params [required, String] :key
    #   The object key.
    #
    # @option params [String] :range
    #   HeadObject returns only the metadata for an object. If the Range is
    #   satisfiable, only the `ContentLength` is affected in the response. If
    #   the Range is not satisfiable, S3 returns a `416 - Requested Range Not
    #   Satisfiable` error.
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [Integer] :part_number
    #   Part number of the object being read. This is a positive integer
    #   between 1 and 10,000. Effectively performs a 'ranged' HEAD request
    #   for the part specified. Useful querying about the size of the part and
    #   the number of parts in this object.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :checksum_mode
    #   To retrieve the checksum, this parameter must be enabled.
    #
    #   In addition, if you enable `ChecksumMode` and the object is encrypted
    #   with Amazon Web Services Key Management Service (Amazon Web Services
    #   KMS), you must have permission to use the `kms:Decrypt` action for the
    #   request to succeed.
    #
    # @return [Types::HeadObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::HeadObjectOutput#delete_marker #delete_marker} => Boolean
    #   * {Types::HeadObjectOutput#accept_ranges #accept_ranges} => String
    #   * {Types::HeadObjectOutput#expiration #expiration} => String
    #   * {Types::HeadObjectOutput#restore #restore} => String
    #   * {Types::HeadObjectOutput#archive_status #archive_status} => String
    #   * {Types::HeadObjectOutput#last_modified #last_modified} => Time
    #   * {Types::HeadObjectOutput#content_length #content_length} => Integer
    #   * {Types::HeadObjectOutput#checksum_crc32 #checksum_crc32} => String
    #   * {Types::HeadObjectOutput#checksum_crc32c #checksum_crc32c} => String
    #   * {Types::HeadObjectOutput#checksum_sha1 #checksum_sha1} => String
    #   * {Types::HeadObjectOutput#checksum_sha256 #checksum_sha256} => String
    #   * {Types::HeadObjectOutput#etag #etag} => String
    #   * {Types::HeadObjectOutput#missing_meta #missing_meta} => Integer
    #   * {Types::HeadObjectOutput#version_id #version_id} => String
    #   * {Types::HeadObjectOutput#cache_control #cache_control} => String
    #   * {Types::HeadObjectOutput#content_disposition #content_disposition} => String
    #   * {Types::HeadObjectOutput#content_encoding #content_encoding} => String
    #   * {Types::HeadObjectOutput#content_language #content_language} => String
    #   * {Types::HeadObjectOutput#content_type #content_type} => String
    #   * {Types::HeadObjectOutput#expires #expires} => Time
    #   * {Types::HeadObjectOutput#expires_string #expires_string} => String
    #   * {Types::HeadObjectOutput#website_redirect_location #website_redirect_location} => String
    #   * {Types::HeadObjectOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::HeadObjectOutput#metadata #metadata} => Hash&lt;String,String&gt;
    #   * {Types::HeadObjectOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::HeadObjectOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::HeadObjectOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::HeadObjectOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::HeadObjectOutput#storage_class #storage_class} => String
    #   * {Types::HeadObjectOutput#request_charged #request_charged} => String
    #   * {Types::HeadObjectOutput#replication_status #replication_status} => String
    #   * {Types::HeadObjectOutput#parts_count #parts_count} => Integer
    #   * {Types::HeadObjectOutput#object_lock_mode #object_lock_mode} => String
    #   * {Types::HeadObjectOutput#object_lock_retain_until_date #object_lock_retain_until_date} => Time
    #   * {Types::HeadObjectOutput#object_lock_legal_hold_status #object_lock_legal_hold_status} => String
    #
    #
    # @example Example: To retrieve metadata of an object without returning the object itself
    #
    #   # The following example retrieves an object metadata.
    #
    #   resp = client.head_object({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     accept_ranges: "bytes", 
    #     content_length: 3191, 
    #     content_type: "image/jpeg", 
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     last_modified: Time.parse("Thu, 15 Dec 2016 01:19:41 GMT"), 
    #     metadata: {
    #     }, 
    #     version_id: "null", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.head_object({
    #     bucket: "BucketName", # required
    #     if_match: "IfMatch",
    #     if_modified_since: Time.now,
    #     if_none_match: "IfNoneMatch",
    #     if_unmodified_since: Time.now,
    #     key: "ObjectKey", # required
    #     range: "Range",
    #     version_id: "ObjectVersionId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     part_number: 1,
    #     expected_bucket_owner: "AccountId",
    #     checksum_mode: "ENABLED", # accepts ENABLED
    #   })
    #
    # @example Response structure
    #
    #   resp.delete_marker #=> Boolean
    #   resp.accept_ranges #=> String
    #   resp.expiration #=> String
    #   resp.restore #=> String
    #   resp.archive_status #=> String, one of "ARCHIVE_ACCESS", "DEEP_ARCHIVE_ACCESS"
    #   resp.last_modified #=> Time
    #   resp.content_length #=> Integer
    #   resp.checksum_crc32 #=> String
    #   resp.checksum_crc32c #=> String
    #   resp.checksum_sha1 #=> String
    #   resp.checksum_sha256 #=> String
    #   resp.etag #=> String
    #   resp.missing_meta #=> Integer
    #   resp.version_id #=> String
    #   resp.cache_control #=> String
    #   resp.content_disposition #=> String
    #   resp.content_encoding #=> String
    #   resp.content_language #=> String
    #   resp.content_type #=> String
    #   resp.expires #=> Time
    #   resp.expires_string #=> String
    #   resp.website_redirect_location #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.metadata #=> Hash
    #   resp.metadata["MetadataKey"] #=> String
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.request_charged #=> String, one of "requester"
    #   resp.replication_status #=> String, one of "COMPLETE", "PENDING", "FAILED", "REPLICA"
    #   resp.parts_count #=> Integer
    #   resp.object_lock_mode #=> String, one of "GOVERNANCE", "COMPLIANCE"
    #   resp.object_lock_retain_until_date #=> Time
    #   resp.object_lock_legal_hold_status #=> String, one of "ON", "OFF"
    #
    #
    # The following waiters are defined for this operation (see {Client#wait_until} for detailed usage):
    #
    #   * object_exists
    #   * object_not_exists
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/HeadObject AWS API Documentation
    #
    # @overload head_object(params = {})
    # @param [Hash] params ({})
    def head_object(params = {}, options = {})
      req = build_request(:head_object, params)
      req.send_request(options)
    end

    # Lists the analytics configurations for the bucket. You can have up to
    # 1,000 analytics configurations per bucket.
    #
    # This action supports list pagination and does not return more than 100
    # configurations at a time. You should always check the `IsTruncated`
    # element in the response. If there are no more configurations to list,
    # `IsTruncated` is set to false. If there are more configurations to
    # list, `IsTruncated` is set to true, and there will be a value in
    # `NextContinuationToken`. You use the `NextContinuationToken` value to
    # continue the pagination of the list by passing the value in
    # continuation-token in the request to `GET` the next page.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetAnalyticsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about Amazon S3 analytics feature, see [Amazon S3
    # Analytics – Storage Class Analysis][3].
    #
    # The following operations are related to
    # `ListBucketAnalyticsConfigurations`:
    #
    # * [GetBucketAnalyticsConfiguration][4]
    #
    # * [DeleteBucketAnalyticsConfiguration][5]
    #
    # * [PutBucketAnalyticsConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketAnalyticsConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket from which analytics configurations are
    #   retrieved.
    #
    # @option params [String] :continuation_token
    #   The ContinuationToken that represents a placeholder from where this
    #   request should begin.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::ListBucketAnalyticsConfigurationsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListBucketAnalyticsConfigurationsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListBucketAnalyticsConfigurationsOutput#continuation_token #continuation_token} => String
    #   * {Types::ListBucketAnalyticsConfigurationsOutput#next_continuation_token #next_continuation_token} => String
    #   * {Types::ListBucketAnalyticsConfigurationsOutput#analytics_configuration_list #analytics_configuration_list} => Array&lt;Types::AnalyticsConfiguration&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_bucket_analytics_configurations({
    #     bucket: "BucketName", # required
    #     continuation_token: "Token",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.continuation_token #=> String
    #   resp.next_continuation_token #=> String
    #   resp.analytics_configuration_list #=> Array
    #   resp.analytics_configuration_list[0].id #=> String
    #   resp.analytics_configuration_list[0].filter.prefix #=> String
    #   resp.analytics_configuration_list[0].filter.tag.key #=> String
    #   resp.analytics_configuration_list[0].filter.tag.value #=> String
    #   resp.analytics_configuration_list[0].filter.and.prefix #=> String
    #   resp.analytics_configuration_list[0].filter.and.tags #=> Array
    #   resp.analytics_configuration_list[0].filter.and.tags[0].key #=> String
    #   resp.analytics_configuration_list[0].filter.and.tags[0].value #=> String
    #   resp.analytics_configuration_list[0].storage_class_analysis.data_export.output_schema_version #=> String, one of "V_1"
    #   resp.analytics_configuration_list[0].storage_class_analysis.data_export.destination.s3_bucket_destination.format #=> String, one of "CSV"
    #   resp.analytics_configuration_list[0].storage_class_analysis.data_export.destination.s3_bucket_destination.bucket_account_id #=> String
    #   resp.analytics_configuration_list[0].storage_class_analysis.data_export.destination.s3_bucket_destination.bucket #=> String
    #   resp.analytics_configuration_list[0].storage_class_analysis.data_export.destination.s3_bucket_destination.prefix #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketAnalyticsConfigurations AWS API Documentation
    #
    # @overload list_bucket_analytics_configurations(params = {})
    # @param [Hash] params ({})
    def list_bucket_analytics_configurations(params = {}, options = {})
      req = build_request(:list_bucket_analytics_configurations, params)
      req.send_request(options)
    end

    # Lists the S3 Intelligent-Tiering configuration from the specified
    # bucket.
    #
    # The S3 Intelligent-Tiering storage class is designed to optimize
    # storage costs by automatically moving data to the most cost-effective
    # storage access tier, without performance impact or operational
    # overhead. S3 Intelligent-Tiering delivers automatic cost savings in
    # three low latency and high throughput access tiers. To get the lowest
    # storage cost on data that can be accessed in minutes to hours, you can
    # choose to activate additional archiving capabilities.
    #
    # The S3 Intelligent-Tiering storage class is the ideal storage class
    # for data with unknown, changing, or unpredictable access patterns,
    # independent of object size or retention period. If the size of an
    # object is less than 128 KB, it is not monitored and not eligible for
    # auto-tiering. Smaller objects can be stored, but they are always
    # charged at the Frequent Access tier rates in the S3
    # Intelligent-Tiering storage class.
    #
    # For more information, see [Storage class for automatically optimizing
    # frequently and infrequently accessed objects][1].
    #
    # Operations related to `ListBucketIntelligentTieringConfigurations`
    # include:
    #
    # * [DeleteBucketIntelligentTieringConfiguration][2]
    #
    # * [PutBucketIntelligentTieringConfiguration][3]
    #
    # * [GetBucketIntelligentTieringConfiguration][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketIntelligentTieringConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #
    # @option params [String] :continuation_token
    #   The `ContinuationToken` that represents a placeholder from where this
    #   request should begin.
    #
    # @return [Types::ListBucketIntelligentTieringConfigurationsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListBucketIntelligentTieringConfigurationsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListBucketIntelligentTieringConfigurationsOutput#continuation_token #continuation_token} => String
    #   * {Types::ListBucketIntelligentTieringConfigurationsOutput#next_continuation_token #next_continuation_token} => String
    #   * {Types::ListBucketIntelligentTieringConfigurationsOutput#intelligent_tiering_configuration_list #intelligent_tiering_configuration_list} => Array&lt;Types::IntelligentTieringConfiguration&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_bucket_intelligent_tiering_configurations({
    #     bucket: "BucketName", # required
    #     continuation_token: "Token",
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.continuation_token #=> String
    #   resp.next_continuation_token #=> String
    #   resp.intelligent_tiering_configuration_list #=> Array
    #   resp.intelligent_tiering_configuration_list[0].id #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.prefix #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.tag.key #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.tag.value #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.and.prefix #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.and.tags #=> Array
    #   resp.intelligent_tiering_configuration_list[0].filter.and.tags[0].key #=> String
    #   resp.intelligent_tiering_configuration_list[0].filter.and.tags[0].value #=> String
    #   resp.intelligent_tiering_configuration_list[0].status #=> String, one of "Enabled", "Disabled"
    #   resp.intelligent_tiering_configuration_list[0].tierings #=> Array
    #   resp.intelligent_tiering_configuration_list[0].tierings[0].days #=> Integer
    #   resp.intelligent_tiering_configuration_list[0].tierings[0].access_tier #=> String, one of "ARCHIVE_ACCESS", "DEEP_ARCHIVE_ACCESS"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketIntelligentTieringConfigurations AWS API Documentation
    #
    # @overload list_bucket_intelligent_tiering_configurations(params = {})
    # @param [Hash] params ({})
    def list_bucket_intelligent_tiering_configurations(params = {}, options = {})
      req = build_request(:list_bucket_intelligent_tiering_configurations, params)
      req.send_request(options)
    end

    # Returns a list of inventory configurations for the bucket. You can
    # have up to 1,000 analytics configurations per bucket.
    #
    # This action supports list pagination and does not return more than 100
    # configurations at a time. Always check the `IsTruncated` element in
    # the response. If there are no more configurations to list,
    # `IsTruncated` is set to false. If there are more configurations to
    # list, `IsTruncated` is set to true, and there is a value in
    # `NextContinuationToken`. You use the `NextContinuationToken` value to
    # continue the pagination of the list by passing the value in
    # continuation-token in the request to `GET` the next page.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetInventoryConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about the Amazon S3 inventory feature, see [Amazon S3
    # Inventory][3]
    #
    # The following operations are related to
    # `ListBucketInventoryConfigurations`:
    #
    # * [GetBucketInventoryConfiguration][4]
    #
    # * [DeleteBucketInventoryConfiguration][5]
    #
    # * [PutBucketInventoryConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketInventoryConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the inventory configurations to
    #   retrieve.
    #
    # @option params [String] :continuation_token
    #   The marker used to continue an inventory configuration listing that
    #   has been truncated. Use the NextContinuationToken from a previously
    #   truncated list response to continue the listing. The continuation
    #   token is an opaque value that Amazon S3 understands.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::ListBucketInventoryConfigurationsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListBucketInventoryConfigurationsOutput#continuation_token #continuation_token} => String
    #   * {Types::ListBucketInventoryConfigurationsOutput#inventory_configuration_list #inventory_configuration_list} => Array&lt;Types::InventoryConfiguration&gt;
    #   * {Types::ListBucketInventoryConfigurationsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListBucketInventoryConfigurationsOutput#next_continuation_token #next_continuation_token} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_bucket_inventory_configurations({
    #     bucket: "BucketName", # required
    #     continuation_token: "Token",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.continuation_token #=> String
    #   resp.inventory_configuration_list #=> Array
    #   resp.inventory_configuration_list[0].destination.s3_bucket_destination.account_id #=> String
    #   resp.inventory_configuration_list[0].destination.s3_bucket_destination.bucket #=> String
    #   resp.inventory_configuration_list[0].destination.s3_bucket_destination.format #=> String, one of "CSV", "ORC", "Parquet"
    #   resp.inventory_configuration_list[0].destination.s3_bucket_destination.prefix #=> String
    #   resp.inventory_configuration_list[0].destination.s3_bucket_destination.encryption.ssekms.key_id #=> String
    #   resp.inventory_configuration_list[0].is_enabled #=> Boolean
    #   resp.inventory_configuration_list[0].filter.prefix #=> String
    #   resp.inventory_configuration_list[0].id #=> String
    #   resp.inventory_configuration_list[0].included_object_versions #=> String, one of "All", "Current"
    #   resp.inventory_configuration_list[0].optional_fields #=> Array
    #   resp.inventory_configuration_list[0].optional_fields[0] #=> String, one of "Size", "LastModifiedDate", "StorageClass", "ETag", "IsMultipartUploaded", "ReplicationStatus", "EncryptionStatus", "ObjectLockRetainUntilDate", "ObjectLockMode", "ObjectLockLegalHoldStatus", "IntelligentTieringAccessTier", "BucketKeyStatus", "ChecksumAlgorithm"
    #   resp.inventory_configuration_list[0].schedule.frequency #=> String, one of "Daily", "Weekly"
    #   resp.is_truncated #=> Boolean
    #   resp.next_continuation_token #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketInventoryConfigurations AWS API Documentation
    #
    # @overload list_bucket_inventory_configurations(params = {})
    # @param [Hash] params ({})
    def list_bucket_inventory_configurations(params = {}, options = {})
      req = build_request(:list_bucket_inventory_configurations, params)
      req.send_request(options)
    end

    # Lists the metrics configurations for the bucket. The metrics
    # configurations are only for the request metrics of the bucket and do
    # not provide information on daily storage metrics. You can have up to
    # 1,000 configurations per bucket.
    #
    # This action supports list pagination and does not return more than 100
    # configurations at a time. Always check the `IsTruncated` element in
    # the response. If there are no more configurations to list,
    # `IsTruncated` is set to false. If there are more configurations to
    # list, `IsTruncated` is set to true, and there is a value in
    # `NextContinuationToken`. You use the `NextContinuationToken` value to
    # continue the pagination of the list by passing the value in
    # `continuation-token` in the request to `GET` the next page.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:GetMetricsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For more information about metrics configurations and CloudWatch
    # request metrics, see [Monitoring Metrics with Amazon CloudWatch][3].
    #
    # The following operations are related to
    # `ListBucketMetricsConfigurations`:
    #
    # * [PutBucketMetricsConfiguration][4]
    #
    # * [GetBucketMetricsConfiguration][5]
    #
    # * [DeleteBucketMetricsConfiguration][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketMetricsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the metrics configurations to
    #   retrieve.
    #
    # @option params [String] :continuation_token
    #   The marker that is used to continue a metrics configuration listing
    #   that has been truncated. Use the NextContinuationToken from a
    #   previously truncated list response to continue the listing. The
    #   continuation token is an opaque value that Amazon S3 understands.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::ListBucketMetricsConfigurationsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListBucketMetricsConfigurationsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListBucketMetricsConfigurationsOutput#continuation_token #continuation_token} => String
    #   * {Types::ListBucketMetricsConfigurationsOutput#next_continuation_token #next_continuation_token} => String
    #   * {Types::ListBucketMetricsConfigurationsOutput#metrics_configuration_list #metrics_configuration_list} => Array&lt;Types::MetricsConfiguration&gt;
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_bucket_metrics_configurations({
    #     bucket: "BucketName", # required
    #     continuation_token: "Token",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.continuation_token #=> String
    #   resp.next_continuation_token #=> String
    #   resp.metrics_configuration_list #=> Array
    #   resp.metrics_configuration_list[0].id #=> String
    #   resp.metrics_configuration_list[0].filter.prefix #=> String
    #   resp.metrics_configuration_list[0].filter.tag.key #=> String
    #   resp.metrics_configuration_list[0].filter.tag.value #=> String
    #   resp.metrics_configuration_list[0].filter.access_point_arn #=> String
    #   resp.metrics_configuration_list[0].filter.and.prefix #=> String
    #   resp.metrics_configuration_list[0].filter.and.tags #=> Array
    #   resp.metrics_configuration_list[0].filter.and.tags[0].key #=> String
    #   resp.metrics_configuration_list[0].filter.and.tags[0].value #=> String
    #   resp.metrics_configuration_list[0].filter.and.access_point_arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBucketMetricsConfigurations AWS API Documentation
    #
    # @overload list_bucket_metrics_configurations(params = {})
    # @param [Hash] params ({})
    def list_bucket_metrics_configurations(params = {}, options = {})
      req = build_request(:list_bucket_metrics_configurations, params)
      req.send_request(options)
    end

    # Returns a list of all buckets owned by the authenticated sender of the
    # request. To use this operation, you must have the
    # `s3:ListAllMyBuckets` permission.
    #
    # For information about Amazon S3 buckets, see [Creating, configuring,
    # and working with Amazon S3 buckets][1].
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-buckets-s3.html
    #
    # @return [Types::ListBucketsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListBucketsOutput#buckets #buckets} => Array&lt;Types::Bucket&gt;
    #   * {Types::ListBucketsOutput#owner #owner} => Types::Owner
    #
    #
    # @example Example: To list all buckets
    #
    #   # The following example returns all the buckets owned by the sender of this request.
    #
    #   resp = client.list_buckets({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     buckets: [
    #       {
    #         creation_date: Time.parse("2012-02-15T21:03:02.000Z"), 
    #         name: "examplebucket", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2011-07-24T19:33:50.000Z"), 
    #         name: "examplebucket2", 
    #       }, 
    #       {
    #         creation_date: Time.parse("2010-12-17T00:56:49.000Z"), 
    #         name: "examplebucket3", 
    #       }, 
    #     ], 
    #     owner: {
    #       display_name: "own-display-name", 
    #       id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31", 
    #     }, 
    #   }
    #
    # @example Response structure
    #
    #   resp.buckets #=> Array
    #   resp.buckets[0].name #=> String
    #   resp.buckets[0].creation_date #=> Time
    #   resp.owner.display_name #=> String
    #   resp.owner.id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListBuckets AWS API Documentation
    #
    # @overload list_buckets(params = {})
    # @param [Hash] params ({})
    def list_buckets(params = {}, options = {})
      req = build_request(:list_buckets, params)
      req.send_request(options)
    end

    # This action lists in-progress multipart uploads. An in-progress
    # multipart upload is a multipart upload that has been initiated using
    # the Initiate Multipart Upload request, but has not yet been completed
    # or aborted.
    #
    # This action returns at most 1,000 multipart uploads in the response.
    # 1,000 multipart uploads is the maximum number of uploads a response
    # can include, which is also the default value. You can further limit
    # the number of uploads in a response by specifying the `max-uploads`
    # parameter in the response. If additional multipart uploads satisfy the
    # list criteria, the response will contain an `IsTruncated` element with
    # the value true. To list the additional multipart uploads, use the
    # `key-marker` and `upload-id-marker` request parameters.
    #
    # In the response, the uploads are sorted by key. If your application
    # has initiated more than one multipart upload using the same object
    # key, then uploads in the response are first sorted by key.
    # Additionally, uploads are sorted in ascending order within each key by
    # the upload initiation time.
    #
    # For more information on multipart uploads, see [Uploading Objects
    # Using Multipart Upload][1].
    #
    # For information on permissions required to use the multipart upload
    # API, see [Multipart Upload and Permissions][2].
    #
    # The following operations are related to `ListMultipartUploads`:
    #
    # * [CreateMultipartUpload][3]
    #
    # * [UploadPart][4]
    #
    # * [CompleteMultipartUpload][5]
    #
    # * [ListParts][6]
    #
    # * [AbortMultipartUpload][7]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :delimiter
    #   Character you use to group keys.
    #
    #   All keys that contain the same string between the prefix, if
    #   specified, and the first occurrence of the delimiter after the prefix
    #   are grouped under a single result element, `CommonPrefixes`. If you
    #   don't specify the prefix parameter, then the substring starts at the
    #   beginning of the key. The keys that are grouped under `CommonPrefixes`
    #   result element are not returned elsewhere in the response.
    #
    # @option params [String] :encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #
    # @option params [String] :key_marker
    #   Together with upload-id-marker, this parameter specifies the multipart
    #   upload after which listing should begin.
    #
    #   If `upload-id-marker` is not specified, only the keys
    #   lexicographically greater than the specified `key-marker` will be
    #   included in the list.
    #
    #   If `upload-id-marker` is specified, any multipart uploads for a key
    #   equal to the `key-marker` might also be included, provided those
    #   multipart uploads have upload IDs lexicographically greater than the
    #   specified `upload-id-marker`.
    #
    # @option params [Integer] :max_uploads
    #   Sets the maximum number of multipart uploads, from 1 to 1,000, to
    #   return in the response body. 1,000 is the maximum number of uploads
    #   that can be returned in a response.
    #
    # @option params [String] :prefix
    #   Lists in-progress uploads only for those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different grouping of keys. (You can think of using prefix to make
    #   groups in the same way you'd use a folder in a file system.)
    #
    # @option params [String] :upload_id_marker
    #   Together with key-marker, specifies the multipart upload after which
    #   listing should begin. If key-marker is not specified, the
    #   upload-id-marker parameter is ignored. Otherwise, any multipart
    #   uploads for a key equal to the key-marker might be included in the
    #   list only if they have an upload ID lexicographically greater than the
    #   specified `upload-id-marker`.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @return [Types::ListMultipartUploadsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListMultipartUploadsOutput#bucket #bucket} => String
    #   * {Types::ListMultipartUploadsOutput#key_marker #key_marker} => String
    #   * {Types::ListMultipartUploadsOutput#upload_id_marker #upload_id_marker} => String
    #   * {Types::ListMultipartUploadsOutput#next_key_marker #next_key_marker} => String
    #   * {Types::ListMultipartUploadsOutput#prefix #prefix} => String
    #   * {Types::ListMultipartUploadsOutput#delimiter #delimiter} => String
    #   * {Types::ListMultipartUploadsOutput#next_upload_id_marker #next_upload_id_marker} => String
    #   * {Types::ListMultipartUploadsOutput#max_uploads #max_uploads} => Integer
    #   * {Types::ListMultipartUploadsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListMultipartUploadsOutput#uploads #uploads} => Array&lt;Types::MultipartUpload&gt;
    #   * {Types::ListMultipartUploadsOutput#common_prefixes #common_prefixes} => Array&lt;Types::CommonPrefix&gt;
    #   * {Types::ListMultipartUploadsOutput#encoding_type #encoding_type} => String
    #   * {Types::ListMultipartUploadsOutput#request_charged #request_charged} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: List next set of multipart uploads when previous result is truncated
    #
    #   # The following example specifies the upload-id-marker and key-marker from previous truncated response to retrieve next
    #   # setup of multipart uploads.
    #
    #   resp = client.list_multipart_uploads({
    #     bucket: "examplebucket", 
    #     key_marker: "nextkeyfrompreviousresponse", 
    #     max_uploads: 2, 
    #     upload_id_marker: "valuefrompreviousresponse", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     bucket: "acl1", 
    #     is_truncated: true, 
    #     key_marker: "", 
    #     max_uploads: 2, 
    #     next_key_marker: "someobjectkey", 
    #     next_upload_id_marker: "examplelo91lv1iwvWpvCiJWugw2xXLPAD7Z8cJyX9.WiIRgNrdG6Ldsn.9FtS63TCl1Uf5faTB.1U5Ckcbmdw--", 
    #     upload_id_marker: "", 
    #     uploads: [
    #       {
    #         initiated: Time.parse("2014-05-01T05:40:58.000Z"), 
    #         initiator: {
    #           display_name: "ownder-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         key: "JavaFile", 
    #         owner: {
    #           display_name: "mohanataws", 
    #           id: "852b113e7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         storage_class: "STANDARD", 
    #         upload_id: "gZ30jIqlUa.CInXklLQtSMJITdUnoZ1Y5GACB5UckOtspm5zbDMCkPF_qkfZzMiFZ6dksmcnqxJyIBvQMG9X9Q--", 
    #       }, 
    #       {
    #         initiated: Time.parse("2014-05-01T05:41:27.000Z"), 
    #         initiator: {
    #           display_name: "ownder-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         key: "JavaFile", 
    #         owner: {
    #           display_name: "ownder-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         storage_class: "STANDARD", 
    #         upload_id: "b7tZSqIlo91lv1iwvWpvCiJWugw2xXLPAD7Z8cJyX9.WiIRgNrdG6Ldsn.9FtS63TCl1Uf5faTB.1U5Ckcbmdw--", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Example: To list in-progress multipart uploads on a bucket
    #
    #   # The following example lists in-progress multipart uploads on a specific bucket.
    #
    #   resp = client.list_multipart_uploads({
    #     bucket: "examplebucket", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     uploads: [
    #       {
    #         initiated: Time.parse("2014-05-01T05:40:58.000Z"), 
    #         initiator: {
    #           display_name: "display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         key: "JavaFile", 
    #         owner: {
    #           display_name: "display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         storage_class: "STANDARD", 
    #         upload_id: "examplelUa.CInXklLQtSMJITdUnoZ1Y5GACB5UckOtspm5zbDMCkPF_qkfZzMiFZ6dksmcnqxJyIBvQMG9X9Q--", 
    #       }, 
    #       {
    #         initiated: Time.parse("2014-05-01T05:41:27.000Z"), 
    #         initiator: {
    #           display_name: "display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         key: "JavaFile", 
    #         owner: {
    #           display_name: "display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         storage_class: "STANDARD", 
    #         upload_id: "examplelo91lv1iwvWpvCiJWugw2xXLPAD7Z8cJyX9.WiIRgNrdG6Ldsn.9FtS63TCl1Uf5faTB.1U5Ckcbmdw--", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_multipart_uploads({
    #     bucket: "BucketName", # required
    #     delimiter: "Delimiter",
    #     encoding_type: "url", # accepts url
    #     key_marker: "KeyMarker",
    #     max_uploads: 1,
    #     prefix: "Prefix",
    #     upload_id_marker: "UploadIdMarker",
    #     expected_bucket_owner: "AccountId",
    #     request_payer: "requester", # accepts requester
    #   })
    #
    # @example Response structure
    #
    #   resp.bucket #=> String
    #   resp.key_marker #=> String
    #   resp.upload_id_marker #=> String
    #   resp.next_key_marker #=> String
    #   resp.prefix #=> String
    #   resp.delimiter #=> String
    #   resp.next_upload_id_marker #=> String
    #   resp.max_uploads #=> Integer
    #   resp.is_truncated #=> Boolean
    #   resp.uploads #=> Array
    #   resp.uploads[0].upload_id #=> String
    #   resp.uploads[0].key #=> String
    #   resp.uploads[0].initiated #=> Time
    #   resp.uploads[0].storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.uploads[0].owner.display_name #=> String
    #   resp.uploads[0].owner.id #=> String
    #   resp.uploads[0].initiator.id #=> String
    #   resp.uploads[0].initiator.display_name #=> String
    #   resp.uploads[0].checksum_algorithm #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #   resp.common_prefixes #=> Array
    #   resp.common_prefixes[0].prefix #=> String
    #   resp.encoding_type #=> String, one of "url"
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListMultipartUploads AWS API Documentation
    #
    # @overload list_multipart_uploads(params = {})
    # @param [Hash] params ({})
    def list_multipart_uploads(params = {}, options = {})
      req = build_request(:list_multipart_uploads, params)
      req.send_request(options)
    end

    # Returns metadata about all versions of the objects in a bucket. You
    # can also use request parameters as selection criteria to return
    # metadata about a subset of all the object versions.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:ListBucketVersions` action. Be aware of the name difference.
    #
    # <note markdown="1"> A 200 OK response can contain valid or invalid XML. Make sure to
    # design your application to parse the contents of the response and
    # handle it appropriately.
    #
    #  </note>
    #
    # To use this operation, you must have READ access to the bucket.
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # The following operations are related to `ListObjectVersions`:
    #
    # * [ListObjectsV2][1]
    #
    # * [GetObject][2]
    #
    # * [PutObject][3]
    #
    # * [DeleteObject][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    #
    # @option params [required, String] :bucket
    #   The bucket name that contains the objects.
    #
    # @option params [String] :delimiter
    #   A delimiter is a character that you specify to group keys. All keys
    #   that contain the same string between the `prefix` and the first
    #   occurrence of the delimiter are grouped under a single result element
    #   in CommonPrefixes. These groups are counted as one result against the
    #   max-keys limitation. These keys are not returned elsewhere in the
    #   response.
    #
    # @option params [String] :encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #
    # @option params [String] :key_marker
    #   Specifies the key to start with when listing objects in a bucket.
    #
    # @option params [Integer] :max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the action returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more. If additional keys satisfy the
    #   search criteria, but were not returned because max-keys was exceeded,
    #   the response contains &lt;isTruncated&gt;true&lt;/isTruncated&gt;. To
    #   return the additional keys, see key-marker and version-id-marker.
    #
    # @option params [String] :prefix
    #   Use this parameter to select only those keys that begin with the
    #   specified prefix. You can use prefixes to separate a bucket into
    #   different groupings of keys. (You can think of using prefix to make
    #   groups in the same way you'd use a folder in a file system.) You can
    #   use prefix with delimiter to roll up numerous objects into a single
    #   result under CommonPrefixes.
    #
    # @option params [String] :version_id_marker
    #   Specifies the object version you want to start listing from.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @return [Types::ListObjectVersionsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListObjectVersionsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListObjectVersionsOutput#key_marker #key_marker} => String
    #   * {Types::ListObjectVersionsOutput#version_id_marker #version_id_marker} => String
    #   * {Types::ListObjectVersionsOutput#next_key_marker #next_key_marker} => String
    #   * {Types::ListObjectVersionsOutput#next_version_id_marker #next_version_id_marker} => String
    #   * {Types::ListObjectVersionsOutput#versions #versions} => Array&lt;Types::ObjectVersion&gt;
    #   * {Types::ListObjectVersionsOutput#delete_markers #delete_markers} => Array&lt;Types::DeleteMarkerEntry&gt;
    #   * {Types::ListObjectVersionsOutput#name #name} => String
    #   * {Types::ListObjectVersionsOutput#prefix #prefix} => String
    #   * {Types::ListObjectVersionsOutput#delimiter #delimiter} => String
    #   * {Types::ListObjectVersionsOutput#max_keys #max_keys} => Integer
    #   * {Types::ListObjectVersionsOutput#common_prefixes #common_prefixes} => Array&lt;Types::CommonPrefix&gt;
    #   * {Types::ListObjectVersionsOutput#encoding_type #encoding_type} => String
    #   * {Types::ListObjectVersionsOutput#request_charged #request_charged} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list object versions
    #
    #   # The following example return versions of an object with specific key name prefix. The request limits the number of items
    #   # returned to two. If there are are more than two object version, S3 returns NextToken in the response. You can specify
    #   # this token value in your next request to fetch next set of object versions.
    #
    #   resp = client.list_object_versions({
    #     bucket: "examplebucket", 
    #     prefix: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     versions: [
    #       {
    #         etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #         is_latest: true, 
    #         key: "HappyFace.jpg", 
    #         last_modified: Time.parse("2016-12-15T01:19:41.000Z"), 
    #         owner: {
    #           display_name: "owner-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         size: 3191, 
    #         storage_class: "STANDARD", 
    #         version_id: "null", 
    #       }, 
    #       {
    #         etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #         is_latest: false, 
    #         key: "HappyFace.jpg", 
    #         last_modified: Time.parse("2016-12-13T00:58:26.000Z"), 
    #         owner: {
    #           display_name: "owner-display-name", 
    #           id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         size: 3191, 
    #         storage_class: "STANDARD", 
    #         version_id: "PHtexPGjH2y.zBgT8LmB7wwLI2mpbz.k", 
    #       }, 
    #     ], 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_object_versions({
    #     bucket: "BucketName", # required
    #     delimiter: "Delimiter",
    #     encoding_type: "url", # accepts url
    #     key_marker: "KeyMarker",
    #     max_keys: 1,
    #     prefix: "Prefix",
    #     version_id_marker: "VersionIdMarker",
    #     expected_bucket_owner: "AccountId",
    #     request_payer: "requester", # accepts requester
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.key_marker #=> String
    #   resp.version_id_marker #=> String
    #   resp.next_key_marker #=> String
    #   resp.next_version_id_marker #=> String
    #   resp.versions #=> Array
    #   resp.versions[0].etag #=> String
    #   resp.versions[0].checksum_algorithm #=> Array
    #   resp.versions[0].checksum_algorithm[0] #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #   resp.versions[0].size #=> Integer
    #   resp.versions[0].storage_class #=> String, one of "STANDARD"
    #   resp.versions[0].key #=> String
    #   resp.versions[0].version_id #=> String
    #   resp.versions[0].is_latest #=> Boolean
    #   resp.versions[0].last_modified #=> Time
    #   resp.versions[0].owner.display_name #=> String
    #   resp.versions[0].owner.id #=> String
    #   resp.delete_markers #=> Array
    #   resp.delete_markers[0].owner.display_name #=> String
    #   resp.delete_markers[0].owner.id #=> String
    #   resp.delete_markers[0].key #=> String
    #   resp.delete_markers[0].version_id #=> String
    #   resp.delete_markers[0].is_latest #=> Boolean
    #   resp.delete_markers[0].last_modified #=> Time
    #   resp.name #=> String
    #   resp.prefix #=> String
    #   resp.delimiter #=> String
    #   resp.max_keys #=> Integer
    #   resp.common_prefixes #=> Array
    #   resp.common_prefixes[0].prefix #=> String
    #   resp.encoding_type #=> String, one of "url"
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectVersions AWS API Documentation
    #
    # @overload list_object_versions(params = {})
    # @param [Hash] params ({})
    def list_object_versions(params = {}, options = {})
      req = build_request(:list_object_versions, params)
      req.send_request(options)
    end

    # Returns some or all (up to 1,000) of the objects in a bucket. You can
    # use the request parameters as selection criteria to return a subset of
    # the objects in a bucket. A 200 OK response can contain valid or
    # invalid XML. Be sure to design your application to parse the contents
    # of the response and handle it appropriately.
    #
    # This action has been revised. We recommend that you use the newer
    # version, [ListObjectsV2][1], when developing applications. For
    # backward compatibility, Amazon S3 continues to support `ListObjects`.
    #
    # The following operations are related to `ListObjects`:
    #
    # * [ListObjectsV2][1]
    #
    # * [GetObject][2]
    #
    # * [PutObject][3]
    #
    # * [CreateBucket][4]
    #
    # * [ListBuckets][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket containing the objects.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :delimiter
    #   A delimiter is a character you use to group keys.
    #
    # @option params [String] :encoding_type
    #   Requests Amazon S3 to encode the object keys in the response and
    #   specifies the encoding method to use. An object key may contain any
    #   Unicode character; however, XML 1.0 parser cannot parse some
    #   characters, such as characters with an ASCII value from 0 to 10. For
    #   characters that are not supported in XML 1.0, you can add this
    #   parameter to request that Amazon S3 encode the keys in the response.
    #
    # @option params [String] :marker
    #   Marker is where you want Amazon S3 to start listing from. Amazon S3
    #   starts listing after this specified key. Marker can be any key in the
    #   bucket.
    #
    # @option params [Integer] :max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the action returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more.
    #
    # @option params [String] :prefix
    #   Limits the response to keys that begin with the specified prefix.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request. Bucket owners need not specify this
    #   parameter in their requests.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::ListObjectsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListObjectsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListObjectsOutput#marker #marker} => String
    #   * {Types::ListObjectsOutput#next_marker #next_marker} => String
    #   * {Types::ListObjectsOutput#contents #contents} => Array&lt;Types::Object&gt;
    #   * {Types::ListObjectsOutput#name #name} => String
    #   * {Types::ListObjectsOutput#prefix #prefix} => String
    #   * {Types::ListObjectsOutput#delimiter #delimiter} => String
    #   * {Types::ListObjectsOutput#max_keys #max_keys} => Integer
    #   * {Types::ListObjectsOutput#common_prefixes #common_prefixes} => Array&lt;Types::CommonPrefix&gt;
    #   * {Types::ListObjectsOutput#encoding_type #encoding_type} => String
    #   * {Types::ListObjectsOutput#request_charged #request_charged} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list objects in a bucket
    #
    #   # The following example list two objects in a bucket.
    #
    #   resp = client.list_objects({
    #     bucket: "examplebucket", 
    #     max_keys: 2, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     contents: [
    #       {
    #         etag: "\"70ee1738b6b21e2c8a43f3a5ab0eee71\"", 
    #         key: "example1.jpg", 
    #         last_modified: Time.parse("2014-11-21T19:40:05.000Z"), 
    #         owner: {
    #           display_name: "myname", 
    #           id: "12345example25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         size: 11, 
    #         storage_class: "STANDARD", 
    #       }, 
    #       {
    #         etag: "\"9c8af9a76df052144598c115ef33e511\"", 
    #         key: "example2.jpg", 
    #         last_modified: Time.parse("2013-11-15T01:10:49.000Z"), 
    #         owner: {
    #           display_name: "myname", 
    #           id: "12345example25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #         }, 
    #         size: 713193, 
    #         storage_class: "STANDARD", 
    #       }, 
    #     ], 
    #     next_marker: "eyJNYXJrZXIiOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAyfQ==", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_objects({
    #     bucket: "BucketName", # required
    #     delimiter: "Delimiter",
    #     encoding_type: "url", # accepts url
    #     marker: "Marker",
    #     max_keys: 1,
    #     prefix: "Prefix",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.marker #=> String
    #   resp.next_marker #=> String
    #   resp.contents #=> Array
    #   resp.contents[0].key #=> String
    #   resp.contents[0].last_modified #=> Time
    #   resp.contents[0].etag #=> String
    #   resp.contents[0].checksum_algorithm #=> Array
    #   resp.contents[0].checksum_algorithm[0] #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #   resp.contents[0].size #=> Integer
    #   resp.contents[0].storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.contents[0].owner.display_name #=> String
    #   resp.contents[0].owner.id #=> String
    #   resp.name #=> String
    #   resp.prefix #=> String
    #   resp.delimiter #=> String
    #   resp.max_keys #=> Integer
    #   resp.common_prefixes #=> Array
    #   resp.common_prefixes[0].prefix #=> String
    #   resp.encoding_type #=> String, one of "url"
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjects AWS API Documentation
    #
    # @overload list_objects(params = {})
    # @param [Hash] params ({})
    def list_objects(params = {}, options = {})
      req = build_request(:list_objects, params)
      req.send_request(options)
    end

    # Returns some or all (up to 1,000) of the objects in a bucket with each
    # request. You can use the request parameters as selection criteria to
    # return a subset of the objects in a bucket. A `200 OK` response can
    # contain valid or invalid XML. Make sure to design your application to
    # parse the contents of the response and handle it appropriately.
    # Objects are returned sorted in an ascending order of the respective
    # key names in the list. For more information about listing objects, see
    # [Listing object keys programmatically][1]
    #
    # To use this operation, you must have READ access to the bucket.
    #
    # To use this action in an Identity and Access Management (IAM) policy,
    # you must have permissions to perform the `s3:ListBucket` action. The
    # bucket owner has this permission by default and can grant this
    # permission to others. For more information about permissions, see
    # [Permissions Related to Bucket Subresource Operations][2] and
    # [Managing Access Permissions to Your Amazon S3 Resources][3].
    #
    # This section describes the latest revision of this action. We
    # recommend that you use this revised API for application development.
    # For backward compatibility, Amazon S3 continues to support the prior
    # version of this API, [ListObjects][4].
    #
    # To get a list of your buckets, see [ListBuckets][5].
    #
    # The following operations are related to `ListObjectsV2`:
    #
    # * [GetObject][6]
    #
    # * [PutObject][7]
    #
    # * [CreateBucket][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ListingKeysUsingAPIs.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjects.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    #
    # @option params [required, String] :bucket
    #   Bucket name to list.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :delimiter
    #   A delimiter is a character you use to group keys.
    #
    # @option params [String] :encoding_type
    #   Encoding type used by Amazon S3 to encode object keys in the response.
    #
    # @option params [Integer] :max_keys
    #   Sets the maximum number of keys returned in the response. By default
    #   the action returns up to 1,000 key names. The response might contain
    #   fewer keys but will never contain more.
    #
    # @option params [String] :prefix
    #   Limits the response to keys that begin with the specified prefix.
    #
    # @option params [String] :continuation_token
    #   ContinuationToken indicates Amazon S3 that the list is being continued
    #   on this bucket with a token. ContinuationToken is obfuscated and is
    #   not a real key.
    #
    # @option params [Boolean] :fetch_owner
    #   The owner field is not present in listV2 by default, if you want to
    #   return owner field with each key in the result then set the fetch
    #   owner field to true.
    #
    # @option params [String] :start_after
    #   StartAfter is where you want Amazon S3 to start listing from. Amazon
    #   S3 starts listing after this specified key. StartAfter can be any key
    #   in the bucket.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that she or he will be charged for
    #   the list objects request in V2 style. Bucket owners need not specify
    #   this parameter in their requests.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::ListObjectsV2Output] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListObjectsV2Output#is_truncated #is_truncated} => Boolean
    #   * {Types::ListObjectsV2Output#contents #contents} => Array&lt;Types::Object&gt;
    #   * {Types::ListObjectsV2Output#name #name} => String
    #   * {Types::ListObjectsV2Output#prefix #prefix} => String
    #   * {Types::ListObjectsV2Output#delimiter #delimiter} => String
    #   * {Types::ListObjectsV2Output#max_keys #max_keys} => Integer
    #   * {Types::ListObjectsV2Output#common_prefixes #common_prefixes} => Array&lt;Types::CommonPrefix&gt;
    #   * {Types::ListObjectsV2Output#encoding_type #encoding_type} => String
    #   * {Types::ListObjectsV2Output#key_count #key_count} => Integer
    #   * {Types::ListObjectsV2Output#continuation_token #continuation_token} => String
    #   * {Types::ListObjectsV2Output#next_continuation_token #next_continuation_token} => String
    #   * {Types::ListObjectsV2Output#start_after #start_after} => String
    #   * {Types::ListObjectsV2Output#request_charged #request_charged} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To get object list
    #
    #   # The following example retrieves object list. The request specifies max keys to limit response to include only 2 object
    #   # keys. 
    #
    #   resp = client.list_objects_v2({
    #     bucket: "DOC-EXAMPLE-BUCKET", 
    #     max_keys: 2, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     contents: [
    #       {
    #         etag: "\"70ee1738b6b21e2c8a43f3a5ab0eee71\"", 
    #         key: "happyface.jpg", 
    #         last_modified: Time.parse("2014-11-21T19:40:05.000Z"), 
    #         size: 11, 
    #         storage_class: "STANDARD", 
    #       }, 
    #       {
    #         etag: "\"becf17f89c30367a9a44495d62ed521a-1\"", 
    #         key: "test.jpg", 
    #         last_modified: Time.parse("2014-05-02T04:51:50.000Z"), 
    #         size: 4192256, 
    #         storage_class: "STANDARD", 
    #       }, 
    #     ], 
    #     is_truncated: true, 
    #     key_count: 2, 
    #     max_keys: 2, 
    #     name: "DOC-EXAMPLE-BUCKET", 
    #     next_continuation_token: "1w41l63U0xa8q7smH50vCxyTQqdxo69O3EmK28Bi5PcROI4wI/EyIJg==", 
    #     prefix: "", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_objects_v2({
    #     bucket: "BucketName", # required
    #     delimiter: "Delimiter",
    #     encoding_type: "url", # accepts url
    #     max_keys: 1,
    #     prefix: "Prefix",
    #     continuation_token: "Token",
    #     fetch_owner: false,
    #     start_after: "StartAfter",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.is_truncated #=> Boolean
    #   resp.contents #=> Array
    #   resp.contents[0].key #=> String
    #   resp.contents[0].last_modified #=> Time
    #   resp.contents[0].etag #=> String
    #   resp.contents[0].checksum_algorithm #=> Array
    #   resp.contents[0].checksum_algorithm[0] #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #   resp.contents[0].size #=> Integer
    #   resp.contents[0].storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "GLACIER", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.contents[0].owner.display_name #=> String
    #   resp.contents[0].owner.id #=> String
    #   resp.name #=> String
    #   resp.prefix #=> String
    #   resp.delimiter #=> String
    #   resp.max_keys #=> Integer
    #   resp.common_prefixes #=> Array
    #   resp.common_prefixes[0].prefix #=> String
    #   resp.encoding_type #=> String, one of "url"
    #   resp.key_count #=> Integer
    #   resp.continuation_token #=> String
    #   resp.next_continuation_token #=> String
    #   resp.start_after #=> String
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListObjectsV2 AWS API Documentation
    #
    # @overload list_objects_v2(params = {})
    # @param [Hash] params ({})
    def list_objects_v2(params = {}, options = {})
      req = build_request(:list_objects_v2, params)
      req.send_request(options)
    end

    # Lists the parts that have been uploaded for a specific multipart
    # upload. This operation must include the upload ID, which you obtain by
    # sending the initiate multipart upload request (see
    # [CreateMultipartUpload][1]). This request returns a maximum of 1,000
    # uploaded parts. The default number of parts returned is 1,000 parts.
    # You can restrict the number of parts returned by specifying the
    # `max-parts` request parameter. If your multipart upload consists of
    # more than 1,000 parts, the response returns an `IsTruncated` field
    # with the value of true, and a `NextPartNumberMarker` element. In
    # subsequent `ListParts` requests you can include the part-number-marker
    # query string parameter and set its value to the `NextPartNumberMarker`
    # field value from the previous response.
    #
    # If the upload was created using a checksum algorithm, you will need to
    # have permission to the `kms:Decrypt` action for the request to
    # succeed.
    #
    # For more information on multipart uploads, see [Uploading Objects
    # Using Multipart Upload][2].
    #
    # For information on permissions required to use the multipart upload
    # API, see [Multipart Upload and Permissions][3].
    #
    # The following operations are related to `ListParts`:
    #
    # * [CreateMultipartUpload][1]
    #
    # * [UploadPart][4]
    #
    # * [CompleteMultipartUpload][5]
    #
    # * [AbortMultipartUpload][6]
    #
    # * [GetObjectAttributes][7]
    #
    # * [ListMultipartUploads][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAttributes.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to which the parts are being uploaded.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Object key for which the multipart upload was initiated.
    #
    # @option params [Integer] :max_parts
    #   Sets the maximum number of parts to return.
    #
    # @option params [Integer] :part_number_marker
    #   Specifies the part after which listing should begin. Only parts with
    #   higher part numbers will be listed.
    #
    # @option params [required, String] :upload_id
    #   Upload ID identifying the multipart upload whose parts are being
    #   listed.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the object.
    #   This parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This parameter
    #   is needed only when the object was created using a checksum algorithm.
    #   For more information, see [Protecting data using SSE-C keys][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a checksum
    #   algorithm. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @return [Types::ListPartsOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::ListPartsOutput#abort_date #abort_date} => Time
    #   * {Types::ListPartsOutput#abort_rule_id #abort_rule_id} => String
    #   * {Types::ListPartsOutput#bucket #bucket} => String
    #   * {Types::ListPartsOutput#key #key} => String
    #   * {Types::ListPartsOutput#upload_id #upload_id} => String
    #   * {Types::ListPartsOutput#part_number_marker #part_number_marker} => Integer
    #   * {Types::ListPartsOutput#next_part_number_marker #next_part_number_marker} => Integer
    #   * {Types::ListPartsOutput#max_parts #max_parts} => Integer
    #   * {Types::ListPartsOutput#is_truncated #is_truncated} => Boolean
    #   * {Types::ListPartsOutput#parts #parts} => Array&lt;Types::Part&gt;
    #   * {Types::ListPartsOutput#initiator #initiator} => Types::Initiator
    #   * {Types::ListPartsOutput#owner #owner} => Types::Owner
    #   * {Types::ListPartsOutput#storage_class #storage_class} => String
    #   * {Types::ListPartsOutput#request_charged #request_charged} => String
    #   * {Types::ListPartsOutput#checksum_algorithm #checksum_algorithm} => String
    #
    # The returned {Seahorse::Client::Response response} is a pageable response and is Enumerable. For details on usage see {Aws::PageableResponse PageableResponse}.
    #
    #
    # @example Example: To list parts of a multipart upload.
    #
    #   # The following example lists parts uploaded for a specific multipart upload.
    #
    #   resp = client.list_parts({
    #     bucket: "examplebucket", 
    #     key: "bigobject", 
    #     upload_id: "example7YPBOJuoFiQ9cz4P3Pe6FIZwO4f7wN93uHsNBEw97pl5eNwzExg0LAT2dUN91cOmrEQHDsP3WA60CEg--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     initiator: {
    #       display_name: "owner-display-name", 
    #       id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #     }, 
    #     owner: {
    #       display_name: "owner-display-name", 
    #       id: "examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484be31bebcc", 
    #     }, 
    #     parts: [
    #       {
    #         etag: "\"d8c2eafd90c266e19ab9dcacc479f8af\"", 
    #         last_modified: Time.parse("2016-12-16T00:11:42.000Z"), 
    #         part_number: 1, 
    #         size: 26246026, 
    #       }, 
    #       {
    #         etag: "\"d8c2eafd90c266e19ab9dcacc479f8af\"", 
    #         last_modified: Time.parse("2016-12-16T00:15:01.000Z"), 
    #         part_number: 2, 
    #         size: 26246026, 
    #       }, 
    #     ], 
    #     storage_class: "STANDARD", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.list_parts({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     max_parts: 1,
    #     part_number_marker: 1,
    #     upload_id: "MultipartUploadId", # required
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #   })
    #
    # @example Response structure
    #
    #   resp.abort_date #=> Time
    #   resp.abort_rule_id #=> String
    #   resp.bucket #=> String
    #   resp.key #=> String
    #   resp.upload_id #=> String
    #   resp.part_number_marker #=> Integer
    #   resp.next_part_number_marker #=> Integer
    #   resp.max_parts #=> Integer
    #   resp.is_truncated #=> Boolean
    #   resp.parts #=> Array
    #   resp.parts[0].part_number #=> Integer
    #   resp.parts[0].last_modified #=> Time
    #   resp.parts[0].etag #=> String
    #   resp.parts[0].size #=> Integer
    #   resp.parts[0].checksum_crc32 #=> String
    #   resp.parts[0].checksum_crc32c #=> String
    #   resp.parts[0].checksum_sha1 #=> String
    #   resp.parts[0].checksum_sha256 #=> String
    #   resp.initiator.id #=> String
    #   resp.initiator.display_name #=> String
    #   resp.owner.display_name #=> String
    #   resp.owner.id #=> String
    #   resp.storage_class #=> String, one of "STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE", "OUTPOSTS", "GLACIER_IR", "SNOW"
    #   resp.request_charged #=> String, one of "requester"
    #   resp.checksum_algorithm #=> String, one of "CRC32", "CRC32C", "SHA1", "SHA256"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/ListParts AWS API Documentation
    #
    # @overload list_parts(params = {})
    # @param [Hash] params ({})
    def list_parts(params = {}, options = {})
      req = build_request(:list_parts, params)
      req.send_request(options)
    end

    # Sets the accelerate configuration of an existing bucket. Amazon S3
    # Transfer Acceleration is a bucket-level feature that enables you to
    # perform faster data transfers to Amazon S3.
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutAccelerateConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # The Transfer Acceleration state of a bucket can be set to one of the
    # following two values:
    #
    # * Enabled – Enables accelerated data transfers to the bucket.
    #
    # * Suspended – Disables accelerated data transfers to the bucket.
    #
    # The [GetBucketAccelerateConfiguration][3] action returns the transfer
    # acceleration state of a bucket.
    #
    # After setting the Transfer Acceleration state of a bucket to Enabled,
    # it might take up to thirty minutes before the data transfer rates to
    # the bucket increase.
    #
    # The name of the bucket used for Transfer Acceleration must be
    # DNS-compliant and must not contain periods (".").
    #
    # For more information about transfer acceleration, see [Transfer
    # Acceleration][4].
    #
    # The following operations are related to
    # `PutBucketAccelerateConfiguration`:
    #
    # * [GetBucketAccelerateConfiguration][3]
    #
    # * [CreateBucket][5]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAccelerateConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which the accelerate configuration is set.
    #
    # @option params [required, Types::AccelerateConfiguration] :accelerate_configuration
    #   Container for setting the transfer acceleration state.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_accelerate_configuration({
    #     bucket: "BucketName", # required
    #     accelerate_configuration: { # required
    #       status: "Enabled", # accepts Enabled, Suspended
    #     },
    #     expected_bucket_owner: "AccountId",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAccelerateConfiguration AWS API Documentation
    #
    # @overload put_bucket_accelerate_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_accelerate_configuration(params = {}, options = {})
      req = build_request(:put_bucket_accelerate_configuration, params)
      req.send_request(options)
    end

    # Sets the permissions on an existing bucket using access control lists
    # (ACL). For more information, see [Using ACLs][1]. To set the ACL of a
    # bucket, you must have `WRITE_ACP` permission.
    #
    # You can use one of the following two ways to set a bucket's
    # permissions:
    #
    # * Specify the ACL in the request body
    #
    # * Specify permissions using request headers
    #
    # <note markdown="1"> You cannot specify access permission using both the body and the
    # request headers.
    #
    #  </note>
    #
    # Depending on your application needs, you may choose to set the ACL on
    # a bucket using either the request body or the headers. For example, if
    # you have an existing application that updates a bucket ACL using the
    # request body, then you can continue to use that approach.
    #
    # If your bucket uses the bucket owner enforced setting for S3 Object
    # Ownership, ACLs are disabled and no longer affect permissions. You
    # must use policies to grant access to your bucket and the objects in
    # it. Requests to set ACLs or update ACLs fail and return the
    # `AccessControlListNotSupported` error code. Requests to read ACLs are
    # still supported. For more information, see [Controlling object
    # ownership][2] in the *Amazon S3 User Guide*.
    #
    # Permissions
    #
    # : You can set access permissions by using one of the following
    #   methods:
    #
    #   * Specify a canned ACL with the `x-amz-acl` request header. Amazon
    #     S3 supports a set of predefined ACLs, known as *canned ACLs*. Each
    #     canned ACL has a predefined set of grantees and permissions.
    #     Specify the canned ACL name as the value of `x-amz-acl`. If you
    #     use this header, you cannot use other access control-specific
    #     headers in your request. For more information, see [Canned
    #     ACL][3].
    #
    #   * Specify access permissions explicitly with the `x-amz-grant-read`,
    #     `x-amz-grant-read-acp`, `x-amz-grant-write-acp`, and
    #     `x-amz-grant-full-control` headers. When using these headers, you
    #     specify explicit access permissions and grantees (Amazon Web
    #     Services accounts or Amazon S3 groups) who will receive the
    #     permission. If you use these ACL-specific headers, you cannot use
    #     the `x-amz-acl` header to set a canned ACL. These parameters map
    #     to the set of permissions that Amazon S3 supports in an ACL. For
    #     more information, see [Access Control List (ACL) Overview][4].
    #
    #     You specify each grantee as a type=value pair, where the type is
    #     one of the following:
    #
    #     * `id` – if the value specified is the canonical user ID of an
    #       Amazon Web Services account
    #
    #     * `uri` – if you are granting permissions to a predefined group
    #
    #     * `emailAddress` – if the value specified is the email address of
    #       an Amazon Web Services account
    #
    #       <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #       the following Amazon Web Services Regions:
    #
    #        * US East (N. Virginia)
    #
    #       * US West (N. California)
    #
    #       * US West (Oregon)
    #
    #       * Asia Pacific (Singapore)
    #
    #       * Asia Pacific (Sydney)
    #
    #       * Asia Pacific (Tokyo)
    #
    #       * Europe (Ireland)
    #
    #       * South America (São Paulo)
    #
    #        For a list of all the Amazon S3 supported Regions and endpoints,
    #       see [Regions and Endpoints][5] in the Amazon Web Services
    #       General Reference.
    #
    #        </note>
    #
    #     For example, the following `x-amz-grant-write` header grants
    #     create, overwrite, and delete objects permission to LogDelivery
    #     group predefined by Amazon S3 and two Amazon Web Services accounts
    #     identified by their email addresses.
    #
    #     `x-amz-grant-write:
    #     uri="http://acs.amazonaws.com/groups/s3/LogDelivery",
    #     id="111122223333", id="555566667777" `
    #
    #   You can use either a canned ACL or specify access permissions
    #   explicitly. You cannot do both.
    #
    # Grantee Values
    #
    # : You can specify the person (grantee) to whom you're assigning
    #   access rights (using request elements) in the following ways:
    #
    #   * By the person's ID:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="CanonicalUser"><ID><>ID<></ID><DisplayName><>GranteesEmail<></DisplayName>
    #     </Grantee>`
    #
    #     DisplayName is optional and ignored in the request
    #
    #   * By URI:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="Group"><URI><>http://acs.amazonaws.com/groups/global/AuthenticatedUsers<></URI></Grantee>`
    #
    #   * By Email address:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="AmazonCustomerByEmail"><EmailAddress><>Grantees@email.com<></EmailAddress>&</Grantee>`
    #
    #     The grantee is resolved to the CanonicalUser and, in a response to
    #     a GET Object acl request, appears as the CanonicalUser.
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][5] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    # The following operations are related to `PutBucketAcl`:
    #
    # * [CreateBucket][6]
    #
    # * [DeleteBucket][7]
    #
    # * [GetObjectAcl][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    # [5]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectAcl.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the bucket.
    #
    # @option params [Types::AccessControlPolicy] :access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #
    # @option params [required, String] :bucket
    #   The bucket to which to apply the ACL.
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must be
    #   used as a message integrity check to verify that the request body was
    #   not corrupted in transit. For more information, go to [RFC 1864.][1]
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions on
    #   the bucket.
    #
    # @option params [String] :grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    # @option params [String] :grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Put bucket acl
    #
    #   # The following example replaces existing ACL on a bucket. The ACL grants the bucket owner (specified using the owner ID)
    #   # and write permission to the LogDelivery group. Because this is a replace operation, you must specify all the grants in
    #   # your request. To incrementally add or remove ACL grants, you might use the console.
    #
    #   resp = client.put_bucket_acl({
    #     bucket: "examplebucket", 
    #     grant_full_control: "id=examplee7a2f25102679df27bb0ae12b3f85be6f290b936c4393484", 
    #     grant_write: "uri=http://acs.amazonaws.com/groups/s3/LogDelivery", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_acl({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #     access_control_policy: {
    #       grants: [
    #         {
    #           grantee: {
    #             display_name: "DisplayName",
    #             email_address: "EmailAddress",
    #             id: "ID",
    #             type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #             uri: "URI",
    #           },
    #           permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #         },
    #       ],
    #       owner: {
    #         display_name: "DisplayName",
    #         id: "ID",
    #       },
    #     },
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write: "GrantWrite",
    #     grant_write_acp: "GrantWriteACP",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAcl AWS API Documentation
    #
    # @overload put_bucket_acl(params = {})
    # @param [Hash] params ({})
    def put_bucket_acl(params = {}, options = {})
      req = build_request(:put_bucket_acl, params)
      req.send_request(options)
    end

    # Sets an analytics configuration for the bucket (specified by the
    # analytics configuration ID). You can have up to 1,000 analytics
    # configurations per bucket.
    #
    # You can choose to have storage class analysis export analysis reports
    # sent to a comma-separated values (CSV) flat file. See the `DataExport`
    # request element. Reports are updated daily and are based on the object
    # filters that you configure. When selecting data export, you specify a
    # destination bucket and an optional destination prefix where the file
    # is written. You can export the data to a destination bucket in a
    # different account. However, the destination bucket must be in the same
    # Region as the bucket that you are making the PUT analytics
    # configuration to. For more information, see [Amazon S3 Analytics –
    # Storage Class Analysis][1].
    #
    # You must create a bucket policy on the destination bucket where the
    # exported file is written to grant permissions to Amazon S3 to write
    # objects to the bucket. For an example policy, see [Granting
    # Permissions for Amazon S3 Inventory and Storage Class Analysis][2].
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutAnalyticsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][3] and [Managing Access
    # Permissions to Your Amazon S3 Resources][4].
    #
    # `PutBucketAnalyticsConfiguration` has the following special errors:
    #
    # * * *HTTP Error: HTTP 400 Bad Request*
    #
    #   * *Code: InvalidArgument*
    #
    #   * *Cause: Invalid argument.*
    #
    # * * *HTTP Error: HTTP 400 Bad Request*
    #
    #   * *Code: TooManyConfigurations*
    #
    #   * *Cause: You are attempting to create a new configuration but have
    #     already reached the 1,000-configuration limit.*
    #
    # * * *HTTP Error: HTTP 403 Forbidden*
    #
    #   * *Code: AccessDenied*
    #
    #   * *Cause: You are not the owner of the specified bucket, or you do
    #     not have the s3:PutAnalyticsConfiguration bucket permission to set
    #     the configuration on the bucket.*
    #
    # The following operations are related to
    # `PutBucketAnalyticsConfiguration`:
    #
    # * [GetBucketAnalyticsConfiguration][5]
    #
    # * [DeleteBucketAnalyticsConfiguration][6]
    #
    # * [ListBucketAnalyticsConfigurations][7]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/analytics-storage-class.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-9
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketAnalyticsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketAnalyticsConfiguration.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketAnalyticsConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to which an analytics configuration is stored.
    #
    # @option params [required, String] :id
    #   The ID that identifies the analytics configuration.
    #
    # @option params [required, Types::AnalyticsConfiguration] :analytics_configuration
    #   The configuration and any analyses for the analytics filter.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_analytics_configuration({
    #     bucket: "BucketName", # required
    #     id: "AnalyticsId", # required
    #     analytics_configuration: { # required
    #       id: "AnalyticsId", # required
    #       filter: {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       },
    #       storage_class_analysis: { # required
    #         data_export: {
    #           output_schema_version: "V_1", # required, accepts V_1
    #           destination: { # required
    #             s3_bucket_destination: { # required
    #               format: "CSV", # required, accepts CSV
    #               bucket_account_id: "AccountId",
    #               bucket: "BucketName", # required
    #               prefix: "Prefix",
    #             },
    #           },
    #         },
    #       },
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketAnalyticsConfiguration AWS API Documentation
    #
    # @overload put_bucket_analytics_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_analytics_configuration(params = {}, options = {})
      req = build_request(:put_bucket_analytics_configuration, params)
      req.send_request(options)
    end

    # Sets the `cors` configuration for your bucket. If the configuration
    # exists, Amazon S3 replaces it.
    #
    # To use this operation, you must be allowed to perform the
    # `s3:PutBucketCORS` action. By default, the bucket owner has this
    # permission and can grant it to others.
    #
    # You set this configuration on a bucket so that the bucket can service
    # cross-origin requests. For example, you might want to enable a request
    # whose origin is `http://www.example.com` to access your Amazon S3
    # bucket at `my.example.bucket.com` by using the browser's
    # `XMLHttpRequest` capability.
    #
    # To enable cross-origin resource sharing (CORS) on a bucket, you add
    # the `cors` subresource to the bucket. The `cors` subresource is an XML
    # document in which you configure rules that identify origins and the
    # HTTP methods that can be executed on your bucket. The document is
    # limited to 64 KB in size.
    #
    # When Amazon S3 receives a cross-origin request (or a pre-flight
    # OPTIONS request) against a bucket, it evaluates the `cors`
    # configuration on the bucket and uses the first `CORSRule` rule that
    # matches the incoming browser request to enable a cross-origin request.
    # For a rule to match, the following conditions must be met:
    #
    # * The request's `Origin` header must match `AllowedOrigin` elements.
    #
    # * The request method (for example, GET, PUT, HEAD, and so on) or the
    #   `Access-Control-Request-Method` header in case of a pre-flight
    #   `OPTIONS` request must be one of the `AllowedMethod` elements.
    #
    # * Every header specified in the `Access-Control-Request-Headers`
    #   request header of a pre-flight request must match an `AllowedHeader`
    #   element.
    #
    # For more information about CORS, go to [Enabling Cross-Origin Resource
    # Sharing][1] in the *Amazon S3 User Guide*.
    #
    # The following operations are related to `PutBucketCors`:
    #
    # * [GetBucketCors][2]
    #
    # * [DeleteBucketCors][3]
    #
    # * [RESTOPTIONSobject][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketCors.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketCors.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTOPTIONSobject.html
    #
    # @option params [required, String] :bucket
    #   Specifies the bucket impacted by the `cors`configuration.
    #
    # @option params [required, Types::CORSConfiguration] :cors_configuration
    #   Describes the cross-origin access configuration for objects in an
    #   Amazon S3 bucket. For more information, see [Enabling Cross-Origin
    #   Resource Sharing][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cors.html
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must be
    #   used as a message integrity check to verify that the request body was
    #   not corrupted in transit. For more information, go to [RFC 1864.][1]
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: To set cors configuration on a bucket.
    #
    #   # The following example enables PUT, POST, and DELETE requests from www.example.com, and enables GET requests from any
    #   # domain.
    #
    #   resp = client.put_bucket_cors({
    #     bucket: "", 
    #     cors_configuration: {
    #       cors_rules: [
    #         {
    #           allowed_headers: [
    #             "*", 
    #           ], 
    #           allowed_methods: [
    #             "PUT", 
    #             "POST", 
    #             "DELETE", 
    #           ], 
    #           allowed_origins: [
    #             "http://www.example.com", 
    #           ], 
    #           expose_headers: [
    #             "x-amz-server-side-encryption", 
    #           ], 
    #           max_age_seconds: 3000, 
    #         }, 
    #         {
    #           allowed_headers: [
    #             "Authorization", 
    #           ], 
    #           allowed_methods: [
    #             "GET", 
    #           ], 
    #           allowed_origins: [
    #             "*", 
    #           ], 
    #           max_age_seconds: 3000, 
    #         }, 
    #       ], 
    #     }, 
    #     content_md5: "", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_cors({
    #     bucket: "BucketName", # required
    #     cors_configuration: { # required
    #       cors_rules: [ # required
    #         {
    #           id: "ID",
    #           allowed_headers: ["AllowedHeader"],
    #           allowed_methods: ["AllowedMethod"], # required
    #           allowed_origins: ["AllowedOrigin"], # required
    #           expose_headers: ["ExposeHeader"],
    #           max_age_seconds: 1,
    #         },
    #       ],
    #     },
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketCors AWS API Documentation
    #
    # @overload put_bucket_cors(params = {})
    # @param [Hash] params ({})
    def put_bucket_cors(params = {}, options = {})
      req = build_request(:put_bucket_cors, params)
      req.send_request(options)
    end

    # This action uses the `encryption` subresource to configure default
    # encryption and Amazon S3 Bucket Keys for an existing bucket.
    #
    # By default, all buckets have a default encryption configuration that
    # uses server-side encryption with Amazon S3 managed keys (SSE-S3). You
    # can optionally configure default encryption for a bucket by using
    # server-side encryption with Key Management Service (KMS) keys
    # (SSE-KMS), dual-layer server-side encryption with Amazon Web Services
    # KMS keys (DSSE-KMS), or server-side encryption with customer-provided
    # keys (SSE-C). If you specify default encryption by using SSE-KMS, you
    # can also configure Amazon S3 Bucket Keys. For information about bucket
    # default encryption, see [Amazon S3 bucket default encryption][1] in
    # the *Amazon S3 User Guide*. For more information about S3 Bucket Keys,
    # see [Amazon S3 Bucket Keys][2] in the *Amazon S3 User Guide*.
    #
    # This action requires Amazon Web Services Signature Version 4. For more
    # information, see [ Authenticating Requests (Amazon Web Services
    # Signature Version 4)][3].
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutEncryptionConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][4] and [Managing Access
    # Permissions to Your Amazon S3 Resources][5] in the *Amazon S3 User
    # Guide*.
    #
    # The following operations are related to `PutBucketEncryption`:
    #
    # * [GetBucketEncryption][6]
    #
    # * [DeleteBucketEncryption][7]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-key.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketEncryption.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketEncryption.html
    #
    # @option params [required, String] :bucket
    #   Specifies default encryption for a bucket using server-side encryption
    #   with different key options. By default, all buckets have a default
    #   encryption configuration that uses server-side encryption with Amazon
    #   S3 managed keys (SSE-S3). You can optionally configure default
    #   encryption for a bucket by using server-side encryption with an Amazon
    #   Web Services KMS key (SSE-KMS) or a customer-provided key (SSE-C). For
    #   information about the bucket default encryption feature, see [Amazon
    #   S3 Bucket Default Encryption][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the server-side encryption
    #   configuration.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::ServerSideEncryptionConfiguration] :server_side_encryption_configuration
    #   Specifies the default server-side-encryption configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_encryption({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     server_side_encryption_configuration: { # required
    #       rules: [ # required
    #         {
    #           apply_server_side_encryption_by_default: {
    #             sse_algorithm: "AES256", # required, accepts AES256, aws:kms, aws:kms:dsse
    #             kms_master_key_id: "SSEKMSKeyId",
    #           },
    #           bucket_key_enabled: false,
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketEncryption AWS API Documentation
    #
    # @overload put_bucket_encryption(params = {})
    # @param [Hash] params ({})
    def put_bucket_encryption(params = {}, options = {})
      req = build_request(:put_bucket_encryption, params)
      req.send_request(options)
    end

    # Puts a S3 Intelligent-Tiering configuration to the specified bucket.
    # You can have up to 1,000 S3 Intelligent-Tiering configurations per
    # bucket.
    #
    # The S3 Intelligent-Tiering storage class is designed to optimize
    # storage costs by automatically moving data to the most cost-effective
    # storage access tier, without performance impact or operational
    # overhead. S3 Intelligent-Tiering delivers automatic cost savings in
    # three low latency and high throughput access tiers. To get the lowest
    # storage cost on data that can be accessed in minutes to hours, you can
    # choose to activate additional archiving capabilities.
    #
    # The S3 Intelligent-Tiering storage class is the ideal storage class
    # for data with unknown, changing, or unpredictable access patterns,
    # independent of object size or retention period. If the size of an
    # object is less than 128 KB, it is not monitored and not eligible for
    # auto-tiering. Smaller objects can be stored, but they are always
    # charged at the Frequent Access tier rates in the S3
    # Intelligent-Tiering storage class.
    #
    # For more information, see [Storage class for automatically optimizing
    # frequently and infrequently accessed objects][1].
    #
    # Operations related to `PutBucketIntelligentTieringConfiguration`
    # include:
    #
    # * [DeleteBucketIntelligentTieringConfiguration][2]
    #
    # * [GetBucketIntelligentTieringConfiguration][3]
    #
    # * [ListBucketIntelligentTieringConfigurations][4]
    #
    # <note markdown="1"> You only need S3 Intelligent-Tiering enabled on a bucket if you want
    # to automatically move objects stored in the S3 Intelligent-Tiering
    # storage class to the Archive Access or Deep Archive Access tier.
    #
    #  </note>
    #
    # `PutBucketIntelligentTieringConfiguration` has the following special
    # errors:
    #
    # HTTP 400 Bad Request Error
    #
    # : *Code:* InvalidArgument
    #
    #   *Cause:* Invalid Argument
    #
    # HTTP 400 Bad Request Error
    #
    # : *Code:* TooManyConfigurations
    #
    #   *Cause:* You are attempting to create a new configuration but have
    #   already reached the 1,000-configuration limit.
    #
    # HTTP 403 Forbidden Error
    #
    # : *Cause:* You are not the owner of the specified bucket, or you do
    #   not have the `s3:PutIntelligentTieringConfiguration` bucket
    #   permission to set the configuration on the bucket.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html#sc-dynamic-data-access
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketIntelligentTieringConfiguration.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketIntelligentTieringConfiguration.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketIntelligentTieringConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose configuration you want to
    #   modify or retrieve.
    #
    # @option params [required, String] :id
    #   The ID used to identify the S3 Intelligent-Tiering configuration.
    #
    # @option params [required, Types::IntelligentTieringConfiguration] :intelligent_tiering_configuration
    #   Container for S3 Intelligent-Tiering configuration.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_intelligent_tiering_configuration({
    #     bucket: "BucketName", # required
    #     id: "IntelligentTieringId", # required
    #     intelligent_tiering_configuration: { # required
    #       id: "IntelligentTieringId", # required
    #       filter: {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #         },
    #       },
    #       status: "Enabled", # required, accepts Enabled, Disabled
    #       tierings: [ # required
    #         {
    #           days: 1, # required
    #           access_tier: "ARCHIVE_ACCESS", # required, accepts ARCHIVE_ACCESS, DEEP_ARCHIVE_ACCESS
    #         },
    #       ],
    #     },
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketIntelligentTieringConfiguration AWS API Documentation
    #
    # @overload put_bucket_intelligent_tiering_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_intelligent_tiering_configuration(params = {}, options = {})
      req = build_request(:put_bucket_intelligent_tiering_configuration, params)
      req.send_request(options)
    end

    # This implementation of the `PUT` action adds an inventory
    # configuration (identified by the inventory ID) to the bucket. You can
    # have up to 1,000 inventory configurations per bucket.
    #
    # Amazon S3 inventory generates inventories of the objects in the bucket
    # on a daily or weekly basis, and the results are published to a flat
    # file. The bucket that is inventoried is called the *source* bucket,
    # and the bucket where the inventory flat file is stored is called the
    # *destination* bucket. The *destination* bucket must be in the same
    # Amazon Web Services Region as the *source* bucket.
    #
    # When you configure an inventory for a *source* bucket, you specify the
    # *destination* bucket where you want the inventory to be stored, and
    # whether to generate the inventory daily or weekly. You can also
    # configure what object metadata to include and whether to inventory all
    # object versions or only current versions. For more information, see
    # [Amazon S3 Inventory][1] in the Amazon S3 User Guide.
    #
    # You must create a bucket policy on the *destination* bucket to grant
    # permissions to Amazon S3 to write objects to the bucket in the defined
    # location. For an example policy, see [ Granting Permissions for Amazon
    # S3 Inventory and Storage Class Analysis][2].
    #
    # Permissions
    #
    # : To use this operation, you must have permission to perform the
    #   `s3:PutInventoryConfiguration` action. The bucket owner has this
    #   permission by default and can grant this permission to others.
    #
    #   The `s3:PutInventoryConfiguration` permission allows a user to
    #   create an [S3 Inventory][3] report that includes all object metadata
    #   fields available and to specify the destination bucket to store the
    #   inventory. A user with read access to objects in the destination
    #   bucket can also access all object metadata fields that are available
    #   in the inventory report.
    #
    #   To restrict access to an inventory report, see [Restricting access
    #   to an Amazon S3 Inventory report][4] in the *Amazon S3 User Guide*.
    #   For more information about the metadata fields available in S3
    #   Inventory, see [Amazon S3 Inventory lists][5] in the *Amazon S3 User
    #   Guide*. For more information about permissions, see [Permissions
    #   related to bucket subresource operations][6] and [Identity and
    #   access management in Amazon S3][7] in the *Amazon S3 User Guide*.
    #
    # `PutBucketInventoryConfiguration` has the following special errors:
    #
    # HTTP 400 Bad Request Error
    #
    # : *Code:* InvalidArgument
    #
    #   *Cause:* Invalid Argument
    #
    # HTTP 400 Bad Request Error
    #
    # : *Code:* TooManyConfigurations
    #
    #   *Cause:* You are attempting to create a new configuration but have
    #   already reached the 1,000-configuration limit.
    #
    # HTTP 403 Forbidden Error
    #
    # : *Cause:* You are not the owner of the specified bucket, or you do
    #   not have the `s3:PutInventoryConfiguration` bucket permission to set
    #   the configuration on the bucket.
    #
    # The following operations are related to
    # `PutBucketInventoryConfiguration`:
    #
    # * [GetBucketInventoryConfiguration][8]
    #
    # * [DeleteBucketInventoryConfiguration][9]
    #
    # * [ListBucketInventoryConfigurations][10]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-inventory.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-9
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html#example-bucket-policies-use-case-10
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory.html#storage-inventory-contents
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketInventoryConfiguration.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketInventoryConfiguration.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketInventoryConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket where the inventory configuration will be
    #   stored.
    #
    # @option params [required, String] :id
    #   The ID used to identify the inventory configuration.
    #
    # @option params [required, Types::InventoryConfiguration] :inventory_configuration
    #   Specifies the inventory configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_inventory_configuration({
    #     bucket: "BucketName", # required
    #     id: "InventoryId", # required
    #     inventory_configuration: { # required
    #       destination: { # required
    #         s3_bucket_destination: { # required
    #           account_id: "AccountId",
    #           bucket: "BucketName", # required
    #           format: "CSV", # required, accepts CSV, ORC, Parquet
    #           prefix: "Prefix",
    #           encryption: {
    #             sses3: {
    #             },
    #             ssekms: {
    #               key_id: "SSEKMSKeyId", # required
    #             },
    #           },
    #         },
    #       },
    #       is_enabled: false, # required
    #       filter: {
    #         prefix: "Prefix", # required
    #       },
    #       id: "InventoryId", # required
    #       included_object_versions: "All", # required, accepts All, Current
    #       optional_fields: ["Size"], # accepts Size, LastModifiedDate, StorageClass, ETag, IsMultipartUploaded, ReplicationStatus, EncryptionStatus, ObjectLockRetainUntilDate, ObjectLockMode, ObjectLockLegalHoldStatus, IntelligentTieringAccessTier, BucketKeyStatus, ChecksumAlgorithm
    #       schedule: { # required
    #         frequency: "Daily", # required, accepts Daily, Weekly
    #       },
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketInventoryConfiguration AWS API Documentation
    #
    # @overload put_bucket_inventory_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_inventory_configuration(params = {}, options = {})
      req = build_request(:put_bucket_inventory_configuration, params)
      req.send_request(options)
    end

    # For an updated version of this API, see
    # [PutBucketLifecycleConfiguration][1]. This version has been
    # deprecated. Existing lifecycle configurations will work. For new
    # lifecycle configurations, use the updated API.
    #
    # Creates a new lifecycle configuration for the bucket or replaces an
    # existing lifecycle configuration. For information about lifecycle
    # configuration, see [Object Lifecycle Management][2] in the *Amazon S3
    # User Guide*.
    #
    # By default, all Amazon S3 resources, including buckets, objects, and
    # related subresources (for example, lifecycle configuration and website
    # configuration) are private. Only the resource owner, the Amazon Web
    # Services account that created the resource, can access it. The
    # resource owner can optionally grant access permissions to others by
    # writing an access policy. For this operation, users must get the
    # `s3:PutLifecycleConfiguration` permission.
    #
    # You can also explicitly deny permissions. Explicit denial also
    # supersedes any other permissions. If you want to prevent users or
    # accounts from removing or deleting objects from your bucket, you must
    # deny them permissions for the following actions:
    #
    # * `s3:DeleteObject`
    #
    # * `s3:DeleteObjectVersion`
    #
    # * `s3:PutLifecycleConfiguration`
    #
    # For more information about permissions, see [Managing Access
    # Permissions to your Amazon S3 Resources][3] in the *Amazon S3 User
    # Guide*.
    #
    # For more examples of transitioning objects to storage classes such as
    # STANDARD\_IA or ONEZONE\_IA, see [Examples of Lifecycle
    # Configuration][4].
    #
    # The following operations are related to `PutBucketLifecycle`:
    #
    # * [GetBucketLifecycle][5](Deprecated)
    #
    # * [GetBucketLifecycleConfiguration][6]
    #
    # * [RestoreObject][7]
    #
    # * By default, a resource owner—in this case, a bucket owner, which is
    #   the Amazon Web Services account that created the bucket—can perform
    #   any of the operations. A resource owner can also grant others
    #   permission to perform the operation. For more information, see the
    #   following topics in the Amazon S3 User Guide:
    #
    #   * [Specifying Permissions in a Policy][8]
    #
    #   * [Managing Access Permissions to your Amazon S3 Resources][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html#lifecycle-configuration-examples
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycle.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    #
    # @option params [required, String] :bucket
    #
    # @option params [String] :content_md5
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [Types::LifecycleConfiguration] :lifecycle_configuration
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_lifecycle({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     lifecycle_configuration: {
    #       rules: [ # required
    #         {
    #           expiration: {
    #             date: Time.now,
    #             days: 1,
    #             expired_object_delete_marker: false,
    #           },
    #           id: "ID",
    #           prefix: "Prefix", # required
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           transition: {
    #             date: Time.now,
    #             days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #           },
    #           noncurrent_version_transition: {
    #             noncurrent_days: 1,
    #             storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #             newer_noncurrent_versions: 1,
    #           },
    #           noncurrent_version_expiration: {
    #             noncurrent_days: 1,
    #             newer_noncurrent_versions: 1,
    #           },
    #           abort_incomplete_multipart_upload: {
    #             days_after_initiation: 1,
    #           },
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycle AWS API Documentation
    #
    # @overload put_bucket_lifecycle(params = {})
    # @param [Hash] params ({})
    def put_bucket_lifecycle(params = {}, options = {})
      req = build_request(:put_bucket_lifecycle, params)
      req.send_request(options)
    end

    # Creates a new lifecycle configuration for the bucket or replaces an
    # existing lifecycle configuration. Keep in mind that this will
    # overwrite an existing lifecycle configuration, so if you want to
    # retain any configuration details, they must be included in the new
    # lifecycle configuration. For information about lifecycle
    # configuration, see [Managing your storage lifecycle][1].
    #
    # <note markdown="1"> Bucket lifecycle configuration now supports specifying a lifecycle
    # rule using an object key name prefix, one or more object tags, or a
    # combination of both. Accordingly, this section describes the latest
    # API. The previous version of the API supported filtering based only on
    # an object key name prefix, which is supported for backward
    # compatibility. For the related API description, see
    # [PutBucketLifecycle][2].
    #
    #  </note>
    #
    # Rules
    #
    # : You specify the lifecycle configuration in your request body. The
    #   lifecycle configuration is specified as XML consisting of one or
    #   more rules. An Amazon S3 Lifecycle configuration can have up to
    #   1,000 rules. This limit is not adjustable. Each rule consists of the
    #   following:
    #
    #   * A filter identifying a subset of objects to which the rule
    #     applies. The filter can be based on a key name prefix, object
    #     tags, or a combination of both.
    #
    #   * A status indicating whether the rule is in effect.
    #
    #   * One or more lifecycle transition and expiration actions that you
    #     want Amazon S3 to perform on the objects identified by the filter.
    #     If the state of your bucket is versioning-enabled or
    #     versioning-suspended, you can have many versions of the same
    #     object (one current version and zero or more noncurrent versions).
    #     Amazon S3 provides predefined actions that you can specify for
    #     current and noncurrent object versions.
    #
    #   For more information, see [Object Lifecycle Management][3] and
    #   [Lifecycle Configuration Elements][4].
    #
    # Permissions
    #
    # : By default, all Amazon S3 resources are private, including buckets,
    #   objects, and related subresources (for example, lifecycle
    #   configuration and website configuration). Only the resource owner
    #   (that is, the Amazon Web Services account that created it) can
    #   access the resource. The resource owner can optionally grant access
    #   permissions to others by writing an access policy. For this
    #   operation, a user must get the `s3:PutLifecycleConfiguration`
    #   permission.
    #
    #   You can also explicitly deny permissions. An explicit deny also
    #   supersedes any other permissions. If you want to block users or
    #   accounts from removing or deleting objects from your bucket, you
    #   must deny them permissions for the following actions:
    #
    #   * `s3:DeleteObject`
    #
    #   * `s3:DeleteObjectVersion`
    #
    #   * `s3:PutLifecycleConfiguration`
    #
    #   For more information about permissions, see [Managing Access
    #   Permissions to Your Amazon S3 Resources][5].
    #
    # The following operations are related to
    # `PutBucketLifecycleConfiguration`:
    #
    # * [Examples of Lifecycle Configuration][6]
    #
    # * [GetBucketLifecycleConfiguration][7]
    #
    # * [DeleteBucketLifecycle][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycle.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/intro-lifecycle-rules.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-configuration-examples.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketLifecycle.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to set the configuration.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [Types::BucketLifecycleConfiguration] :lifecycle_configuration
    #   Container for lifecycle rules. You can add as many as 1,000 rules.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Put bucket lifecycle
    #
    #   # The following example replaces existing lifecycle configuration, if any, on the specified bucket. 
    #
    #   resp = client.put_bucket_lifecycle_configuration({
    #     bucket: "examplebucket", 
    #     lifecycle_configuration: {
    #       rules: [
    #         {
    #           expiration: {
    #             days: 3650, 
    #           }, 
    #           filter: {
    #             prefix: "documents/", 
    #           }, 
    #           id: "TestOnly", 
    #           status: "Enabled", 
    #           transitions: [
    #             {
    #               days: 365, 
    #               storage_class: "GLACIER", 
    #             }, 
    #           ], 
    #         }, 
    #       ], 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_lifecycle_configuration({
    #     bucket: "BucketName", # required
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     lifecycle_configuration: {
    #       rules: [ # required
    #         {
    #           expiration: {
    #             date: Time.now,
    #             days: 1,
    #             expired_object_delete_marker: false,
    #           },
    #           id: "ID",
    #           prefix: "Prefix",
    #           filter: {
    #             prefix: "Prefix",
    #             tag: {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #             object_size_greater_than: 1,
    #             object_size_less_than: 1,
    #             and: {
    #               prefix: "Prefix",
    #               tags: [
    #                 {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #               ],
    #               object_size_greater_than: 1,
    #               object_size_less_than: 1,
    #             },
    #           },
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           transitions: [
    #             {
    #               date: Time.now,
    #               days: 1,
    #               storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #             },
    #           ],
    #           noncurrent_version_transitions: [
    #             {
    #               noncurrent_days: 1,
    #               storage_class: "GLACIER", # accepts GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR
    #               newer_noncurrent_versions: 1,
    #             },
    #           ],
    #           noncurrent_version_expiration: {
    #             noncurrent_days: 1,
    #             newer_noncurrent_versions: 1,
    #           },
    #           abort_incomplete_multipart_upload: {
    #             days_after_initiation: 1,
    #           },
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLifecycleConfiguration AWS API Documentation
    #
    # @overload put_bucket_lifecycle_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_lifecycle_configuration(params = {}, options = {})
      req = build_request(:put_bucket_lifecycle_configuration, params)
      req.send_request(options)
    end

    # Set the logging parameters for a bucket and to specify permissions for
    # who can view and modify the logging parameters. All logs are saved to
    # buckets in the same Amazon Web Services Region as the source bucket.
    # To set the logging status of a bucket, you must be the bucket owner.
    #
    # The bucket owner is automatically granted FULL\_CONTROL to all logs.
    # You use the `Grantee` request element to grant access to other people.
    # The `Permissions` request element specifies the kind of access the
    # grantee has to the logs.
    #
    # If the target bucket for log delivery uses the bucket owner enforced
    # setting for S3 Object Ownership, you can't use the `Grantee` request
    # element to grant access to others. Permissions can only be granted
    # using policies. For more information, see [Permissions for server
    # access log delivery][1] in the *Amazon S3 User Guide*.
    #
    # Grantee Values
    #
    # : You can specify the person (grantee) to whom you're assigning
    #   access rights (by using request elements) in the following ways:
    #
    #   * By the person's ID:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="CanonicalUser"><ID><>ID<></ID><DisplayName><>GranteesEmail<></DisplayName>
    #     </Grantee>`
    #
    #     `DisplayName` is optional and ignored in the request.
    #
    #   * By Email address:
    #
    #     ` <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="AmazonCustomerByEmail"><EmailAddress><>Grantees@email.com<></EmailAddress></Grantee>`
    #
    #     The grantee is resolved to the `CanonicalUser` and, in a response
    #     to a `GETObjectAcl` request, appears as the CanonicalUser.
    #
    #   * By URI:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="Group"><URI><>http://acs.amazonaws.com/groups/global/AuthenticatedUsers<></URI></Grantee>`
    #
    # To enable logging, you use `LoggingEnabled` and its children request
    # elements. To disable logging, you use an empty `BucketLoggingStatus`
    # request element:
    #
    # `<BucketLoggingStatus xmlns="http://doc.s3.amazonaws.com/2006-03-01"
    # />`
    #
    # For more information about server access logging, see [Server Access
    # Logging][2] in the *Amazon S3 User Guide*.
    #
    # For more information about creating a bucket, see [CreateBucket][3].
    # For more information about returning the logging status of a bucket,
    # see [GetBucketLogging][4].
    #
    # The following operations are related to `PutBucketLogging`:
    #
    # * [PutObject][5]
    #
    # * [DeleteBucket][6]
    #
    # * [CreateBucket][3]
    #
    # * [GetBucketLogging][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLogging.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which to set the logging parameters.
    #
    # @option params [required, Types::BucketLoggingStatus] :bucket_logging_status
    #   Container for logging status information.
    #
    # @option params [String] :content_md5
    #   The MD5 hash of the `PutBucketLogging` request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set logging configuration for a bucket
    #
    #   # The following example sets logging policy on a bucket. For the Log Delivery group to deliver logs to the destination
    #   # bucket, it needs permission for the READ_ACP action which the policy grants.
    #
    #   resp = client.put_bucket_logging({
    #     bucket: "sourcebucket", 
    #     bucket_logging_status: {
    #       logging_enabled: {
    #         target_bucket: "targetbucket", 
    #         target_grants: [
    #           {
    #             grantee: {
    #               type: "Group", 
    #               uri: "http://acs.amazonaws.com/groups/global/AllUsers", 
    #             }, 
    #             permission: "READ", 
    #           }, 
    #         ], 
    #         target_prefix: "MyBucketLogs/", 
    #       }, 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_logging({
    #     bucket: "BucketName", # required
    #     bucket_logging_status: { # required
    #       logging_enabled: {
    #         target_bucket: "TargetBucket", # required
    #         target_grants: [
    #           {
    #             grantee: {
    #               display_name: "DisplayName",
    #               email_address: "EmailAddress",
    #               id: "ID",
    #               type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #               uri: "URI",
    #             },
    #             permission: "FULL_CONTROL", # accepts FULL_CONTROL, READ, WRITE
    #           },
    #         ],
    #         target_prefix: "TargetPrefix", # required
    #       },
    #     },
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketLogging AWS API Documentation
    #
    # @overload put_bucket_logging(params = {})
    # @param [Hash] params ({})
    def put_bucket_logging(params = {}, options = {})
      req = build_request(:put_bucket_logging, params)
      req.send_request(options)
    end

    # Sets a metrics configuration (specified by the metrics configuration
    # ID) for the bucket. You can have up to 1,000 metrics configurations
    # per bucket. If you're updating an existing metrics configuration,
    # note that this is a full replacement of the existing metrics
    # configuration. If you don't include the elements you want to keep,
    # they are erased.
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutMetricsConfiguration` action. The bucket owner has this
    # permission by default. The bucket owner can grant this permission to
    # others. For more information about permissions, see [Permissions
    # Related to Bucket Subresource Operations][1] and [Managing Access
    # Permissions to Your Amazon S3 Resources][2].
    #
    # For information about CloudWatch request metrics for Amazon S3, see
    # [Monitoring Metrics with Amazon CloudWatch][3].
    #
    # The following operations are related to
    # `PutBucketMetricsConfiguration`:
    #
    # * [DeleteBucketMetricsConfiguration][4]
    #
    # * [GetBucketMetricsConfiguration][5]
    #
    # * [ListBucketMetricsConfigurations][6]
    #
    # `PutBucketMetricsConfiguration` has the following special error:
    #
    # * Error code: `TooManyConfigurations`
    #
    #   * Description: You are attempting to create a new configuration but
    #     have already reached the 1,000-configuration limit.
    #
    #   * HTTP Status Code: HTTP 400 Bad Request
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/cloudwatch-monitoring.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketMetricsConfiguration.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketMetricsConfiguration.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBucketMetricsConfigurations.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket for which the metrics configuration is set.
    #
    # @option params [required, String] :id
    #   The ID used to identify the metrics configuration. The ID has a 64
    #   character limit and can only contain letters, numbers, periods,
    #   dashes, and underscores.
    #
    # @option params [required, Types::MetricsConfiguration] :metrics_configuration
    #   Specifies the metrics configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_metrics_configuration({
    #     bucket: "BucketName", # required
    #     id: "MetricsId", # required
    #     metrics_configuration: { # required
    #       id: "MetricsId", # required
    #       filter: {
    #         prefix: "Prefix",
    #         tag: {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #         access_point_arn: "AccessPointArn",
    #         and: {
    #           prefix: "Prefix",
    #           tags: [
    #             {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #           ],
    #           access_point_arn: "AccessPointArn",
    #         },
    #       },
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketMetricsConfiguration AWS API Documentation
    #
    # @overload put_bucket_metrics_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_metrics_configuration(params = {}, options = {})
      req = build_request(:put_bucket_metrics_configuration, params)
      req.send_request(options)
    end

    # No longer used, see the [PutBucketNotificationConfiguration][1]
    # operation.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketNotificationConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket.
    #
    # @option params [String] :content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::NotificationConfigurationDeprecated] :notification_configuration
    #   The container for the configuration.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_notification({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     notification_configuration: { # required
    #       topic_configuration: {
    #         id: "NotificationId",
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         topic: "TopicArn",
    #       },
    #       queue_configuration: {
    #         id: "NotificationId",
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         queue: "QueueArn",
    #       },
    #       cloud_function_configuration: {
    #         id: "NotificationId",
    #         event: "s3:ReducedRedundancyLostObject", # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         events: ["s3:ReducedRedundancyLostObject"], # accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #         cloud_function: "CloudFunction",
    #         invocation_role: "CloudFunctionInvocationRole",
    #       },
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotification AWS API Documentation
    #
    # @overload put_bucket_notification(params = {})
    # @param [Hash] params ({})
    def put_bucket_notification(params = {}, options = {})
      req = build_request(:put_bucket_notification, params)
      req.send_request(options)
    end

    # Enables notifications of specified events for a bucket. For more
    # information about event notifications, see [Configuring Event
    # Notifications][1].
    #
    # Using this API, you can replace an existing notification
    # configuration. The configuration is an XML file that defines the event
    # types that you want Amazon S3 to publish and the destination where you
    # want Amazon S3 to publish an event notification when it detects an
    # event of the specified type.
    #
    # By default, your bucket has no event notifications configured. That
    # is, the notification configuration will be an empty
    # `NotificationConfiguration`.
    #
    # `<NotificationConfiguration>`
    #
    # `</NotificationConfiguration>`
    #
    # This action replaces the existing notification configuration with the
    # configuration you include in the request body.
    #
    # After Amazon S3 receives this request, it first verifies that any
    # Amazon Simple Notification Service (Amazon SNS) or Amazon Simple Queue
    # Service (Amazon SQS) destination exists, and that the bucket owner has
    # permission to publish to it by sending a test notification. In the
    # case of Lambda destinations, Amazon S3 verifies that the Lambda
    # function permissions grant Amazon S3 permission to invoke the function
    # from the Amazon S3 bucket. For more information, see [Configuring
    # Notifications for Amazon S3 Events][1].
    #
    # You can disable notifications by adding the empty
    # NotificationConfiguration element.
    #
    # For more information about the number of event notification
    # configurations that you can create per bucket, see [Amazon S3 service
    # quotas][2] in *Amazon Web Services General Reference*.
    #
    # By default, only the bucket owner can configure notifications on a
    # bucket. However, bucket owners can use a bucket policy to grant
    # permission to other users to set this configuration with the required
    # `s3:PutBucketNotification` permission.
    #
    # <note markdown="1"> The PUT notification is an atomic operation. For example, suppose your
    # notification configuration includes SNS topic, SQS queue, and Lambda
    # function configurations. When you send a PUT request with this
    # configuration, Amazon S3 sends test messages to your SNS topic. If the
    # message fails, the entire PUT action will fail, and Amazon S3 will not
    # add the configuration to your bucket.
    #
    #  </note>
    #
    # If the configuration in the request body includes only one
    # `TopicConfiguration` specifying only the
    # `s3:ReducedRedundancyLostObject` event type, the response will also
    # include the `x-amz-sns-test-message-id` header containing the message
    # ID of the test notification sent to the topic.
    #
    # The following action is related to
    # `PutBucketNotificationConfiguration`:
    #
    # * [GetBucketNotificationConfiguration][3]
    #
    # ^
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    # [2]: https://docs.aws.amazon.com/general/latest/gr/s3.html#limits_s3
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket.
    #
    # @option params [required, Types::NotificationConfiguration] :notification_configuration
    #   A container for specifying the notification configuration of the
    #   bucket. If this element is empty, notifications are turned off for the
    #   bucket.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [Boolean] :skip_destination_validation
    #   Skips validation of Amazon SQS, Amazon SNS, and Lambda destinations.
    #   True or false value.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set notification configuration for a bucket
    #
    #   # The following example sets notification configuration on a bucket to publish the object created events to an SNS topic.
    #
    #   resp = client.put_bucket_notification_configuration({
    #     bucket: "examplebucket", 
    #     notification_configuration: {
    #       topic_configurations: [
    #         {
    #           events: [
    #             "s3:ObjectCreated:*", 
    #           ], 
    #           topic_arn: "arn:aws:sns:us-west-2:123456789012:s3-notification-topic", 
    #         }, 
    #       ], 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_notification_configuration({
    #     bucket: "BucketName", # required
    #     notification_configuration: { # required
    #       topic_configurations: [
    #         {
    #           id: "NotificationId",
    #           topic_arn: "TopicArn", # required
    #           events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #           filter: {
    #             key: {
    #               filter_rules: [
    #                 {
    #                   name: "prefix", # accepts prefix, suffix
    #                   value: "FilterRuleValue",
    #                 },
    #               ],
    #             },
    #           },
    #         },
    #       ],
    #       queue_configurations: [
    #         {
    #           id: "NotificationId",
    #           queue_arn: "QueueArn", # required
    #           events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #           filter: {
    #             key: {
    #               filter_rules: [
    #                 {
    #                   name: "prefix", # accepts prefix, suffix
    #                   value: "FilterRuleValue",
    #                 },
    #               ],
    #             },
    #           },
    #         },
    #       ],
    #       lambda_function_configurations: [
    #         {
    #           id: "NotificationId",
    #           lambda_function_arn: "LambdaFunctionArn", # required
    #           events: ["s3:ReducedRedundancyLostObject"], # required, accepts s3:ReducedRedundancyLostObject, s3:ObjectCreated:*, s3:ObjectCreated:Put, s3:ObjectCreated:Post, s3:ObjectCreated:Copy, s3:ObjectCreated:CompleteMultipartUpload, s3:ObjectRemoved:*, s3:ObjectRemoved:Delete, s3:ObjectRemoved:DeleteMarkerCreated, s3:ObjectRestore:*, s3:ObjectRestore:Post, s3:ObjectRestore:Completed, s3:Replication:*, s3:Replication:OperationFailedReplication, s3:Replication:OperationNotTracked, s3:Replication:OperationMissedThreshold, s3:Replication:OperationReplicatedAfterThreshold, s3:ObjectRestore:Delete, s3:LifecycleTransition, s3:IntelligentTiering, s3:ObjectAcl:Put, s3:LifecycleExpiration:*, s3:LifecycleExpiration:Delete, s3:LifecycleExpiration:DeleteMarkerCreated, s3:ObjectTagging:*, s3:ObjectTagging:Put, s3:ObjectTagging:Delete
    #           filter: {
    #             key: {
    #               filter_rules: [
    #                 {
    #                   name: "prefix", # accepts prefix, suffix
    #                   value: "FilterRuleValue",
    #                 },
    #               ],
    #             },
    #           },
    #         },
    #       ],
    #       event_bridge_configuration: {
    #       },
    #     },
    #     expected_bucket_owner: "AccountId",
    #     skip_destination_validation: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketNotificationConfiguration AWS API Documentation
    #
    # @overload put_bucket_notification_configuration(params = {})
    # @param [Hash] params ({})
    def put_bucket_notification_configuration(params = {}, options = {})
      req = build_request(:put_bucket_notification_configuration, params)
      req.send_request(options)
    end

    # Creates or modifies `OwnershipControls` for an Amazon S3 bucket. To
    # use this operation, you must have the `s3:PutBucketOwnershipControls`
    # permission. For more information about Amazon S3 permissions, see
    # [Specifying permissions in a policy][1].
    #
    # For information about Amazon S3 Object Ownership, see [Using object
    # ownership][2].
    #
    # The following operations are related to `PutBucketOwnershipControls`:
    #
    # * GetBucketOwnershipControls
    #
    # * DeleteBucketOwnershipControls
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/user-guide/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/user-guide/about-object-ownership.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose `OwnershipControls` you want to
    #   set.
    #
    # @option params [String] :content_md5
    #   The MD5 hash of the `OwnershipControls` request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [required, Types::OwnershipControls] :ownership_controls
    #   The `OwnershipControls` (BucketOwnerEnforced, BucketOwnerPreferred, or
    #   ObjectWriter) that you want to apply to this Amazon S3 bucket.
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_ownership_controls({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     expected_bucket_owner: "AccountId",
    #     ownership_controls: { # required
    #       rules: [ # required
    #         {
    #           object_ownership: "BucketOwnerPreferred", # required, accepts BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
    #         },
    #       ],
    #     },
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketOwnershipControls AWS API Documentation
    #
    # @overload put_bucket_ownership_controls(params = {})
    # @param [Hash] params ({})
    def put_bucket_ownership_controls(params = {}, options = {})
      req = build_request(:put_bucket_ownership_controls, params)
      req.send_request(options)
    end

    # Applies an Amazon S3 bucket policy to an Amazon S3 bucket. If you are
    # using an identity other than the root user of the Amazon Web Services
    # account that owns the bucket, the calling identity must have the
    # `PutBucketPolicy` permissions on the specified bucket and belong to
    # the bucket owner's account in order to use this operation.
    #
    # If you don't have `PutBucketPolicy` permissions, Amazon S3 returns a
    # `403 Access Denied` error. If you have the correct permissions, but
    # you're not using an identity that belongs to the bucket owner's
    # account, Amazon S3 returns a `405 Method Not Allowed` error.
    #
    # To ensure that bucket owners don't inadvertently lock themselves out
    # of their own buckets, the root principal in a bucket owner's Amazon
    # Web Services account can perform the `GetBucketPolicy`,
    # `PutBucketPolicy`, and `DeleteBucketPolicy` API actions, even if their
    # bucket policy explicitly denies the root principal's access. Bucket
    # owner root principals can only be blocked from performing these API
    # actions by VPC endpoint policies and Amazon Web Services Organizations
    # policies.
    #
    # For more information, see [Bucket policy examples][1].
    #
    # The following operations are related to `PutBucketPolicy`:
    #
    # * [CreateBucket][2]
    #
    # * [DeleteBucket][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket.
    #
    # @option params [String] :content_md5
    #   The MD5 hash of the request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [Boolean] :confirm_remove_self_bucket_access
    #   Set this parameter to true to confirm that you want to remove your
    #   permissions to change this bucket policy in the future.
    #
    # @option params [required, String] :policy
    #   The bucket policy as a JSON document.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set bucket policy
    #
    #   # The following example sets a permission policy on a bucket.
    #
    #   resp = client.put_bucket_policy({
    #     bucket: "examplebucket", 
    #     policy: "{\"Version\": \"2012-10-17\", \"Statement\": [{ \"Sid\": \"id-1\",\"Effect\": \"Allow\",\"Principal\": {\"AWS\": \"arn:aws:iam::123456789012:root\"}, \"Action\": [ \"s3:PutObject\",\"s3:PutObjectAcl\"], \"Resource\": [\"arn:aws:s3:::acl3/*\" ] } ]}", 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_policy({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     confirm_remove_self_bucket_access: false,
    #     policy: "Policy", # required
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketPolicy AWS API Documentation
    #
    # @overload put_bucket_policy(params = {})
    # @param [Hash] params ({})
    def put_bucket_policy(params = {}, options = {})
      req = build_request(:put_bucket_policy, params)
      req.send_request(options)
    end

    # Creates a replication configuration or replaces an existing one. For
    # more information, see [Replication][1] in the *Amazon S3 User Guide*.
    #
    # Specify the replication configuration in the request body. In the
    # replication configuration, you provide the name of the destination
    # bucket or buckets where you want Amazon S3 to replicate objects, the
    # IAM role that Amazon S3 can assume to replicate objects on your
    # behalf, and other relevant information.
    #
    # A replication configuration must include at least one rule, and can
    # contain a maximum of 1,000. Each rule identifies a subset of objects
    # to replicate by filtering the objects in the source bucket. To choose
    # additional subsets of objects to replicate, add a rule for each
    # subset.
    #
    # To specify a subset of the objects in the source bucket to apply a
    # replication rule to, add the Filter element as a child of the Rule
    # element. You can filter objects based on an object key prefix, one or
    # more object tags, or both. When you add the Filter element in the
    # configuration, you must also add the following elements:
    # `DeleteMarkerReplication`, `Status`, and `Priority`.
    #
    # <note markdown="1"> If you are using an earlier version of the replication configuration,
    # Amazon S3 handles replication of delete markers differently. For more
    # information, see [Backward Compatibility][2].
    #
    #  </note>
    #
    # For information about enabling versioning on a bucket, see [Using
    # Versioning][3].
    #
    # Handling Replication of Encrypted Objects
    #
    # : By default, Amazon S3 doesn't replicate objects that are stored at
    #   rest using server-side encryption with KMS keys. To replicate Amazon
    #   Web Services KMS-encrypted objects, add the following:
    #   `SourceSelectionCriteria`, `SseKmsEncryptedObjects`, `Status`,
    #   `EncryptionConfiguration`, and `ReplicaKmsKeyID`. For information
    #   about replication configuration, see [Replicating Objects Created
    #   with SSE Using KMS keys][4].
    #
    #   For information on `PutBucketReplication` errors, see [List of
    #   replication-related error codes][5]
    #
    # Permissions
    #
    # : To create a `PutBucketReplication` request, you must have
    #   `s3:PutReplicationConfiguration` permissions for the bucket.
    #
    #   By default, a resource owner, in this case the Amazon Web Services
    #   account that created the bucket, can perform this operation. The
    #   resource owner can also grant others permissions to perform the
    #   operation. For more information about permissions, see [Specifying
    #   Permissions in a Policy][6] and [Managing Access Permissions to Your
    #   Amazon S3 Resources][7].
    #
    #   <note markdown="1"> To perform this operation, the user or role performing the action
    #   must have the [iam:PassRole][8] permission.
    #
    #    </note>
    #
    # The following operations are related to `PutBucketReplication`:
    #
    # * [GetBucketReplication][9]
    #
    # * [DeleteBucketReplication][10]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-add-config.html#replication-backward-compat-considerations
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/Versioning.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/replication-config-for-kms-objects.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#ReplicationErrorCodeList
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_passrole.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketReplication.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketReplication.html
    #
    # @option params [required, String] :bucket
    #   The name of the bucket
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC 1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::ReplicationConfiguration] :replication_configuration
    #   A container for replication rules. You can add up to 1,000 rules. The
    #   maximum size of a replication configuration is 2 MB.
    #
    # @option params [String] :token
    #   A token to allow Object Lock to be enabled for an existing bucket.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set replication configuration on a bucket
    #
    #   # The following example sets replication configuration on a bucket.
    #
    #   resp = client.put_bucket_replication({
    #     bucket: "examplebucket", 
    #     replication_configuration: {
    #       role: "arn:aws:iam::123456789012:role/examplerole", 
    #       rules: [
    #         {
    #           destination: {
    #             bucket: "arn:aws:s3:::destinationbucket", 
    #             storage_class: "STANDARD", 
    #           }, 
    #           prefix: "", 
    #           status: "Enabled", 
    #         }, 
    #       ], 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_replication({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     replication_configuration: { # required
    #       role: "Role", # required
    #       rules: [ # required
    #         {
    #           id: "ID",
    #           priority: 1,
    #           prefix: "Prefix",
    #           filter: {
    #             prefix: "Prefix",
    #             tag: {
    #               key: "ObjectKey", # required
    #               value: "Value", # required
    #             },
    #             and: {
    #               prefix: "Prefix",
    #               tags: [
    #                 {
    #                   key: "ObjectKey", # required
    #                   value: "Value", # required
    #                 },
    #               ],
    #             },
    #           },
    #           status: "Enabled", # required, accepts Enabled, Disabled
    #           source_selection_criteria: {
    #             sse_kms_encrypted_objects: {
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #             },
    #             replica_modifications: {
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #             },
    #           },
    #           existing_object_replication: {
    #             status: "Enabled", # required, accepts Enabled, Disabled
    #           },
    #           destination: { # required
    #             bucket: "BucketName", # required
    #             account: "AccountId",
    #             storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #             access_control_translation: {
    #               owner: "Destination", # required, accepts Destination
    #             },
    #             encryption_configuration: {
    #               replica_kms_key_id: "ReplicaKmsKeyID",
    #             },
    #             replication_time: {
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #               time: { # required
    #                 minutes: 1,
    #               },
    #             },
    #             metrics: {
    #               status: "Enabled", # required, accepts Enabled, Disabled
    #               event_threshold: {
    #                 minutes: 1,
    #               },
    #             },
    #           },
    #           delete_marker_replication: {
    #             status: "Enabled", # accepts Enabled, Disabled
    #           },
    #         },
    #       ],
    #     },
    #     token: "ObjectLockToken",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketReplication AWS API Documentation
    #
    # @overload put_bucket_replication(params = {})
    # @param [Hash] params ({})
    def put_bucket_replication(params = {}, options = {})
      req = build_request(:put_bucket_replication, params)
      req.send_request(options)
    end

    # Sets the request payment configuration for a bucket. By default, the
    # bucket owner pays for downloads from the bucket. This configuration
    # parameter enables the bucket owner (only) to specify that the person
    # requesting the download will be charged for the download. For more
    # information, see [Requester Pays Buckets][1].
    #
    # The following operations are related to `PutBucketRequestPayment`:
    #
    # * [CreateBucket][2]
    #
    # * [GetBucketRequestPayment][3]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RequesterPaysBuckets.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketRequestPayment.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC 1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::RequestPaymentConfiguration] :request_payment_configuration
    #   Container for Payer.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set request payment configuration on a bucket.
    #
    #   # The following example sets request payment configuration on a bucket so that person requesting the download is charged.
    #
    #   resp = client.put_bucket_request_payment({
    #     bucket: "examplebucket", 
    #     request_payment_configuration: {
    #       payer: "Requester", 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_request_payment({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     request_payment_configuration: { # required
    #       payer: "Requester", # required, accepts Requester, BucketOwner
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketRequestPayment AWS API Documentation
    #
    # @overload put_bucket_request_payment(params = {})
    # @param [Hash] params ({})
    def put_bucket_request_payment(params = {}, options = {})
      req = build_request(:put_bucket_request_payment, params)
      req.send_request(options)
    end

    # Sets the tags for a bucket.
    #
    # Use tags to organize your Amazon Web Services bill to reflect your own
    # cost structure. To do this, sign up to get your Amazon Web Services
    # account bill with tag key values included. Then, to see the cost of
    # combined resources, organize your billing information according to
    # resources with the same tag key values. For example, you can tag
    # several resources with a specific application name, and then organize
    # your billing information to see the total cost of that application
    # across several services. For more information, see [Cost Allocation
    # and Tagging][1] and [Using Cost Allocation in Amazon S3 Bucket
    # Tags][2].
    #
    # <note markdown="1"> When this operation sets the tags for a bucket, it will overwrite any
    # current tags the bucket already has. You cannot use this operation to
    # add tags to an existing list of tags.
    #
    #  </note>
    #
    # To use this operation, you must have permissions to perform the
    # `s3:PutBucketTagging` action. The bucket owner has this permission by
    # default and can grant this permission to others. For more information
    # about permissions, see [Permissions Related to Bucket Subresource
    # Operations][3] and [Managing Access Permissions to Your Amazon S3
    # Resources][4].
    #
    # `PutBucketTagging` has the following special errors:
    #
    # * Error code: `InvalidTagError`
    #
    #   * Description: The tag provided was not a valid tag. This error can
    #     occur if the tag did not pass input validation. For information
    #     about tag restrictions, see [User-Defined Tag Restrictions][5] and
    #     [Amazon Web Services-Generated Cost Allocation Tag
    #     Restrictions][6].
    #
    #   ^
    #
    # * Error code: `MalformedXMLError`
    #
    #   * Description: The XML provided does not match the schema.
    #
    #   ^
    #
    # * Error code: `OperationAbortedError `
    #
    #   * Description: A conflicting conditional action is currently in
    #     progress against this resource. Please try again.
    #
    #   ^
    #
    # * Error code: `InternalError`
    #
    #   * Description: The service was unable to apply the provided tag to
    #     the bucket.
    #
    #   ^
    #
    # The following operations are related to `PutBucketTagging`:
    #
    # * [GetBucketTagging][7]
    #
    # * [DeleteBucketTagging][8]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/CostAllocTagging.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [5]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html
    # [6]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/aws-tag-restrictions.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketTagging.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC 1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::Tagging] :tagging
    #   Container for the `TagSet` and `Tag` elements.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set tags on a bucket
    #
    #   # The following example sets tags on a bucket. Any existing tags are replaced.
    #
    #   resp = client.put_bucket_tagging({
    #     bucket: "examplebucket", 
    #     tagging: {
    #       tag_set: [
    #         {
    #           key: "Key1", 
    #           value: "Value1", 
    #         }, 
    #         {
    #           key: "Key2", 
    #           value: "Value2", 
    #         }, 
    #       ], 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_tagging({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     tagging: { # required
    #       tag_set: [ # required
    #         {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketTagging AWS API Documentation
    #
    # @overload put_bucket_tagging(params = {})
    # @param [Hash] params ({})
    def put_bucket_tagging(params = {}, options = {})
      req = build_request(:put_bucket_tagging, params)
      req.send_request(options)
    end

    # Sets the versioning state of an existing bucket.
    #
    # You can set the versioning state with one of the following values:
    #
    # **Enabled**—Enables versioning for the objects in the bucket. All
    # objects added to the bucket receive a unique version ID.
    #
    # **Suspended**—Disables versioning for the objects in the bucket. All
    # objects added to the bucket receive the version ID null.
    #
    # If the versioning state has never been set on a bucket, it has no
    # versioning state; a [GetBucketVersioning][1] request does not return a
    # versioning state value.
    #
    # In order to enable MFA Delete, you must be the bucket owner. If you
    # are the bucket owner and want to enable MFA Delete in the bucket
    # versioning configuration, you must include the `x-amz-mfa request`
    # header and the `Status` and the `MfaDelete` request elements in a
    # request to set the versioning state of the bucket.
    #
    # If you have an object expiration lifecycle configuration in your
    # non-versioned bucket and you want to maintain the same permanent
    # delete behavior when you enable versioning, you must add a noncurrent
    # expiration policy. The noncurrent expiration lifecycle configuration
    # will manage the deletes of the noncurrent object versions in the
    # version-enabled bucket. (A version-enabled bucket maintains one
    # current and zero or more noncurrent object versions.) For more
    # information, see [Lifecycle and Versioning][2].
    #
    # The following operations are related to `PutBucketVersioning`:
    #
    # * [CreateBucket][3]
    #
    # * [DeleteBucket][4]
    #
    # * [GetBucketVersioning][1]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html#lifecycle-and-other-bucket-config
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :content_md5
    #   &gt;The base64-encoded 128-bit MD5 digest of the data. You must use
    #   this header as a message integrity check to verify that the request
    #   body was not corrupted in transit. For more information, see [RFC
    #   1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :mfa
    #   The concatenation of the authentication device's serial number, a
    #   space, and the value that is displayed on your authentication device.
    #
    # @option params [required, Types::VersioningConfiguration] :versioning_configuration
    #   Container for setting the versioning state.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set versioning configuration on a bucket
    #
    #   # The following example sets versioning configuration on bucket. The configuration enables versioning on the bucket.
    #
    #   resp = client.put_bucket_versioning({
    #     bucket: "examplebucket", 
    #     versioning_configuration: {
    #       mfa_delete: "Disabled", 
    #       status: "Enabled", 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_versioning({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     mfa: "MFA",
    #     versioning_configuration: { # required
    #       mfa_delete: "Enabled", # accepts Enabled, Disabled
    #       status: "Enabled", # accepts Enabled, Suspended
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketVersioning AWS API Documentation
    #
    # @overload put_bucket_versioning(params = {})
    # @param [Hash] params ({})
    def put_bucket_versioning(params = {}, options = {})
      req = build_request(:put_bucket_versioning, params)
      req.send_request(options)
    end

    # Sets the configuration of the website that is specified in the
    # `website` subresource. To configure a bucket as a website, you can add
    # this subresource on the bucket with website configuration information
    # such as the file name of the index document and any redirect rules.
    # For more information, see [Hosting Websites on Amazon S3][1].
    #
    # This PUT action requires the `S3:PutBucketWebsite` permission. By
    # default, only the bucket owner can configure the website attached to a
    # bucket; however, bucket owners can allow other users to set the
    # website configuration by writing a bucket policy that grants them the
    # `S3:PutBucketWebsite` permission.
    #
    # To redirect all website requests sent to the bucket's website
    # endpoint, you add a website configuration with the following elements.
    # Because all requests are sent to another website, you don't need to
    # provide index document name for the bucket.
    #
    # * `WebsiteConfiguration`
    #
    # * `RedirectAllRequestsTo`
    #
    # * `HostName`
    #
    # * `Protocol`
    #
    # If you want granular control over redirects, you can use the following
    # elements to add routing rules that describe conditions for redirecting
    # requests and information about the redirect destination. In this case,
    # the website configuration must provide an index document for the
    # bucket, because some requests might not be redirected.
    #
    # * `WebsiteConfiguration`
    #
    # * `IndexDocument`
    #
    # * `Suffix`
    #
    # * `ErrorDocument`
    #
    # * `Key`
    #
    # * `RoutingRules`
    #
    # * `RoutingRule`
    #
    # * `Condition`
    #
    # * `HttpErrorCodeReturnedEquals`
    #
    # * `KeyPrefixEquals`
    #
    # * `Redirect`
    #
    # * `Protocol`
    #
    # * `HostName`
    #
    # * `ReplaceKeyPrefixWith`
    #
    # * `ReplaceKeyWith`
    #
    # * `HttpRedirectCode`
    #
    # Amazon S3 has a limitation of 50 routing rules per website
    # configuration. If you require more than 50 routing rules, you can use
    # object redirect. For more information, see [Configuring an Object
    # Redirect][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. You must use this
    #   header as a message integrity check to verify that the request body
    #   was not corrupted in transit. For more information, see [RFC 1864][1].
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::WebsiteConfiguration] :website_configuration
    #   Container for the request.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    #
    # @example Example: Set website configuration on a bucket
    #
    #   # The following example adds website configuration to a bucket.
    #
    #   resp = client.put_bucket_website({
    #     bucket: "examplebucket", 
    #     content_md5: "", 
    #     website_configuration: {
    #       error_document: {
    #         key: "error.html", 
    #       }, 
    #       index_document: {
    #         suffix: "index.html", 
    #       }, 
    #     }, 
    #   })
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_bucket_website({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     website_configuration: { # required
    #       error_document: {
    #         key: "ObjectKey", # required
    #       },
    #       index_document: {
    #         suffix: "Suffix", # required
    #       },
    #       redirect_all_requests_to: {
    #         host_name: "HostName", # required
    #         protocol: "http", # accepts http, https
    #       },
    #       routing_rules: [
    #         {
    #           condition: {
    #             http_error_code_returned_equals: "HttpErrorCodeReturnedEquals",
    #             key_prefix_equals: "KeyPrefixEquals",
    #           },
    #           redirect: { # required
    #             host_name: "HostName",
    #             http_redirect_code: "HttpRedirectCode",
    #             protocol: "http", # accepts http, https
    #             replace_key_prefix_with: "ReplaceKeyPrefixWith",
    #             replace_key_with: "ReplaceKeyWith",
    #           },
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutBucketWebsite AWS API Documentation
    #
    # @overload put_bucket_website(params = {})
    # @param [Hash] params ({})
    def put_bucket_website(params = {}, options = {})
      req = build_request(:put_bucket_website, params)
      req.send_request(options)
    end

    # Adds an object to a bucket. You must have WRITE permissions on a
    # bucket to add an object to it.
    #
    # <note markdown="1"> Amazon S3 never adds partial objects; if you receive a success
    # response, Amazon S3 added the entire object to the bucket. You cannot
    # use `PutObject` to only update a single piece of metadata for an
    # existing object. You must put the entire object with updated metadata
    # if you want to update some values.
    #
    #  </note>
    #
    # Amazon S3 is a distributed system. If it receives multiple write
    # requests for the same object simultaneously, it overwrites all but the
    # last object written. To prevent objects from being deleted or
    # overwritten, you can use [Amazon S3 Object Lock][1].
    #
    # To ensure that data is not corrupted traversing the network, use the
    # `Content-MD5` header. When you use this header, Amazon S3 checks the
    # object against the provided MD5 value and, if they do not match,
    # returns an error. Additionally, you can calculate the MD5 while
    # putting an object to Amazon S3 and compare the returned ETag to the
    # calculated MD5 value.
    #
    # <note markdown="1"> * To successfully complete the `PutObject` request, you must have the
    #   `s3:PutObject` in your IAM permissions.
    #
    # * To successfully change the objects acl of your `PutObject` request,
    #   you must have the `s3:PutObjectAcl` in your IAM permissions.
    #
    # * To successfully set the tag-set with your `PutObject` request, you
    #   must have the `s3:PutObjectTagging` in your IAM permissions.
    #
    # * The `Content-MD5` header is required for any request to upload an
    #   object with a retention period configured using Amazon S3 Object
    #   Lock. For more information about Amazon S3 Object Lock, see [Amazon
    #   S3 Object Lock Overview][2] in the *Amazon S3 User Guide*.
    #
    #  </note>
    #
    # You have four mutually exclusive options to protect data using
    # server-side encryption in Amazon S3, depending on how you choose to
    # manage the encryption keys. Specifically, the encryption key options
    # are Amazon S3 managed keys (SSE-S3), Amazon Web Services KMS keys
    # (SSE-KMS or DSSE-KMS), and customer-provided keys (SSE-C). Amazon S3
    # encrypts data with server-side encryption by using Amazon S3 managed
    # keys (SSE-S3) by default. You can optionally tell Amazon S3 to encrypt
    # data at rest by using server-side encryption with other key options.
    # For more information, see [Using Server-Side Encryption][3].
    #
    # When adding a new object, you can use headers to grant ACL-based
    # permissions to individual Amazon Web Services accounts or to
    # predefined groups defined by Amazon S3. These permissions are then
    # added to the ACL on the object. By default, all objects are private.
    # Only the owner has full access control. For more information, see
    # [Access Control List (ACL) Overview][4] and [Managing ACLs Using the
    # REST API][5].
    #
    # If the bucket that you're uploading objects to uses the bucket owner
    # enforced setting for S3 Object Ownership, ACLs are disabled and no
    # longer affect permissions. Buckets that use this setting only accept
    # PUT requests that don't specify an ACL or PUT requests that specify
    # bucket owner full control ACLs, such as the
    # `bucket-owner-full-control` canned ACL or an equivalent form of this
    # ACL expressed in the XML format. PUT requests that contain other ACLs
    # (for example, custom grants to certain Amazon Web Services accounts)
    # fail and return a `400` error with the error code
    # `AccessControlListNotSupported`. For more information, see [
    # Controlling ownership of objects and disabling ACLs][6] in the *Amazon
    # S3 User Guide*.
    #
    # <note markdown="1"> If your bucket uses the bucket owner enforced setting for Object
    # Ownership, all objects written to the bucket by any account will be
    # owned by the bucket owner.
    #
    #  </note>
    #
    # By default, Amazon S3 uses the STANDARD Storage Class to store newly
    # created objects. The STANDARD storage class provides high durability
    # and high availability. Depending on performance needs, you can specify
    # a different Storage Class. Amazon S3 on Outposts only uses the
    # OUTPOSTS Storage Class. For more information, see [Storage Classes][7]
    # in the *Amazon S3 User Guide*.
    #
    # If you enable versioning for a bucket, Amazon S3 automatically
    # generates a unique version ID for the object being stored. Amazon S3
    # returns this ID in the response. When you enable versioning for a
    # bucket, if Amazon S3 receives multiple write requests for the same
    # object simultaneously, it stores all of the objects. For more
    # information about versioning, see [Adding Objects to
    # Versioning-Enabled Buckets][8]. For information about returning the
    # versioning state of a bucket, see [GetBucketVersioning][9].
    #
    # For more information about related Amazon S3 APIs, see the following:
    #
    # * [CopyObject][10]
    #
    # * [DeleteObject][11]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock-overview.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-using-rest-api.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/dev/AddingObjectstoVersioningEnabledBuckets.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketVersioning.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObject.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1].
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #
    # @option params [String, StringIO, File] :body
    #   Object data.
    #
    # @option params [required, String] :bucket
    #   The bucket name to which the PUT action was initiated.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :cache_control
    #   Can be used to specify caching behavior along the request/reply chain.
    #   For more information, see
    #   [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9][1].
    #
    #
    #
    #   [1]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
    #
    # @option params [String] :content_disposition
    #   Specifies presentational information for the object. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc6266#section-4][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc6266#section-4
    #
    # @option params [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field. For more information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding
    #
    # @option params [String] :content_language
    #   The language the content is in.
    #
    # @option params [Integer] :content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically. For more information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the message (without the
    #   headers) according to RFC 1864. This header can be used as a message
    #   integrity check to verify that the data is the same data that was
    #   originally sent. Although it is optional, we recommend using the
    #   Content-MD5 mechanism as an end-to-end integrity check. For more
    #   information about REST request authentication, see [REST
    #   Authentication][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
    #
    # @option params [String] :content_type
    #   A standard MIME type describing the format of the contents. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32 checksum of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32C checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 160-bit SHA-1 digest of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 256-bit SHA-256 digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable. For more
    #   information, see
    #   [https://www.rfc-editor.org/rfc/rfc7234#section-5.3][1].
    #
    #
    #
    #   [1]: https://www.rfc-editor.org/rfc/rfc7234#section-5.3
    #
    # @option params [String] :grant_full_control
    #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
    #   object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read
    #   Allows grantee to read the object data and its metadata.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the object ACL.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable object.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :key
    #   Object key for which the PUT action was initiated.
    #
    # @option params [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    #
    # @option params [String] :server_side_encryption
    #   The server-side encryption algorithm used when storing this object in
    #   Amazon S3 (for example, `AES256`, `aws:kms`, `aws:kms:dsse`).
    #
    # @option params [String] :storage_class
    #   By default, Amazon S3 uses the STANDARD Storage Class to store newly
    #   created objects. The STANDARD storage class provides high durability
    #   and high availability. Depending on performance needs, you can specify
    #   a different Storage Class. Amazon S3 on Outposts only uses the
    #   OUTPOSTS Storage Class. For more information, see [Storage Classes][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #
    # @option params [String] :website_redirect_location
    #   If the bucket is configured as a website, redirects requests for this
    #   object to another object in the same bucket or to an external URL.
    #   Amazon S3 stores the value of this header in the object metadata. For
    #   information about object metadata, see [Object Key and Metadata][1].
    #
    #   In the following example, the request header sets the redirect to an
    #   object (anotherPage.html) in the same bucket:
    #
    #   `x-amz-website-redirect-location: /anotherPage.html`
    #
    #   In the following example, the request header sets the object redirect
    #   to another website:
    #
    #   `x-amz-website-redirect-location: http://www.example.com/`
    #
    #   For more information about website hosting in Amazon S3, see [Hosting
    #   Websites on Amazon S3][2] and [How to Configure Website Page
    #   Redirects][3].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html
    #   [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :ssekms_key_id
    #   If `x-amz-server-side-encryption` has a valid value of `aws:kms` or
    #   `aws:kms:dsse`, this header specifies the ID of the Key Management
    #   Service (KMS) symmetric encryption customer managed key that was used
    #   for the object. If you specify `x-amz-server-side-encryption:aws:kms`
    #   or `x-amz-server-side-encryption:aws:kms:dsse`, but do not provide`
    #   x-amz-server-side-encryption-aws-kms-key-id`, Amazon S3 uses the
    #   Amazon Web Services managed key (`aws/s3`) to protect the data. If the
    #   KMS key does not exist in the same account that's issuing the
    #   command, you must use the full ARN and not just the ID.
    #
    # @option params [String] :ssekms_encryption_context
    #   Specifies the Amazon Web Services KMS Encryption Context to use for
    #   object encryption. The value of this header is a base64-encoded UTF-8
    #   string holding JSON with the encryption context key-value pairs. This
    #   value is stored as object metadata and automatically gets passed on to
    #   Amazon Web Services KMS for future `GetObject` or `CopyObject`
    #   operations on this object.
    #
    # @option params [Boolean] :bucket_key_enabled
    #   Specifies whether Amazon S3 should use an S3 Bucket Key for object
    #   encryption with server-side encryption using Key Management Service
    #   (KMS) keys (SSE-KMS). Setting this header to `true` causes Amazon S3
    #   to use an S3 Bucket Key for object encryption with SSE-KMS.
    #
    #   Specifying this header with a PUT action doesn’t affect bucket-level
    #   settings for S3 Bucket Key.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :tagging
    #   The tag-set for the object. The tag-set must be encoded as URL Query
    #   parameters. (For example, "Key1=Value1")
    #
    # @option params [String] :object_lock_mode
    #   The Object Lock mode that you want to apply to this object.
    #
    # @option params [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   The date and time when you want this object's Object Lock to expire.
    #   Must be formatted as a timestamp parameter.
    #
    # @option params [String] :object_lock_legal_hold_status
    #   Specifies whether a legal hold will be applied to this object. For
    #   more information about S3 Object Lock, see [Object Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::PutObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectOutput#expiration #expiration} => String
    #   * {Types::PutObjectOutput#etag #etag} => String
    #   * {Types::PutObjectOutput#checksum_crc32 #checksum_crc32} => String
    #   * {Types::PutObjectOutput#checksum_crc32c #checksum_crc32c} => String
    #   * {Types::PutObjectOutput#checksum_sha1 #checksum_sha1} => String
    #   * {Types::PutObjectOutput#checksum_sha256 #checksum_sha256} => String
    #   * {Types::PutObjectOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::PutObjectOutput#version_id #version_id} => String
    #   * {Types::PutObjectOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::PutObjectOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::PutObjectOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::PutObjectOutput#ssekms_encryption_context #ssekms_encryption_context} => String
    #   * {Types::PutObjectOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::PutObjectOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To upload an object and specify optional tags
    #
    #   # The following example uploads an object. The request specifies optional object tags. The bucket is versioned, therefore
    #   # S3 returns version ID of the newly created object.
    #
    #   resp = client.put_object({
    #     body: "c:\\HappyFace.jpg", 
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #     tagging: "key1=value1&key2=value2", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     version_id: "psM2sYY4.o1501dSx8wMvnkOzSBB.V4a", 
    #   }
    #
    # @example Example: To upload an object and specify canned ACL.
    #
    #   # The following example uploads and object. The request specifies optional canned ACL (access control list) to all READ
    #   # access to authenticated users. If the bucket is versioning enabled, S3 returns version ID in response.
    #
    #   resp = client.put_object({
    #     acl: "authenticated-read", 
    #     body: "filetoupload", 
    #     bucket: "examplebucket", 
    #     key: "exampleobject", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     version_id: "Kirh.unyZwjQ69YxcQLA8z4F5j3kJJKr", 
    #   }
    #
    # @example Example: To create an object.
    #
    #   # The following example creates an object. If the bucket is versioning enabled, S3 returns version ID in response.
    #
    #   resp = client.put_object({
    #     body: "filetoupload", 
    #     bucket: "examplebucket", 
    #     key: "objectkey", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     version_id: "Bvq0EDKxOcXLJXNo_Lkz37eM3R4pfzyQ", 
    #   }
    #
    # @example Example: To upload an object and specify server-side encryption and object tags
    #
    #   # The following example uploads an object. The request specifies the optional server-side encryption option. The request
    #   # also specifies optional object tags. If the bucket is versioning enabled, S3 returns version ID in response.
    #
    #   resp = client.put_object({
    #     body: "filetoupload", 
    #     bucket: "examplebucket", 
    #     key: "exampleobject", 
    #     server_side_encryption: "AES256", 
    #     tagging: "key1=value1&key2=value2", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     server_side_encryption: "AES256", 
    #     version_id: "Ri.vC6qVlA4dEnjgRV4ZHsHoFIjqEMNt", 
    #   }
    #
    # @example Example: To upload object and specify user-defined metadata
    #
    #   # The following example creates an object. The request also specifies optional metadata. If the bucket is versioning
    #   # enabled, S3 returns version ID in response.
    #
    #   resp = client.put_object({
    #     body: "filetoupload", 
    #     bucket: "examplebucket", 
    #     key: "exampleobject", 
    #     metadata: {
    #       "metadata1" => "value1", 
    #       "metadata2" => "value2", 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     version_id: "pSKidl4pHBiNwukdbcPXAIs.sshFFOc0", 
    #   }
    #
    # @example Example: To upload an object
    #
    #   # The following example uploads an object to a versioning-enabled bucket. The source file is specified using Windows file
    #   # syntax. S3 returns VersionId of the newly created object.
    #
    #   resp = client.put_object({
    #     body: "HappyFace.jpg", 
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     version_id: "tpf3zF08nBplQK1XLOefGskR7mGDwcDk", 
    #   }
    #
    # @example Example: To upload an object (specify optional headers)
    #
    #   # The following example uploads an object. The request specifies optional request headers to directs S3 to use specific
    #   # storage class and use server-side encryption.
    #
    #   resp = client.put_object({
    #     body: "HappyFace.jpg", 
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #     server_side_encryption: "AES256", 
    #     storage_class: "STANDARD_IA", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"6805f2cfc46c0f04559748bb039d69ae\"", 
    #     server_side_encryption: "AES256", 
    #     version_id: "CG612hodqujkf8FaaNfp8U..FIhLROcp", 
    #   }
    #
    # @example Streaming a file from disk
    #   # upload file from disk in a single request, may not exceed 5GB
    #   File.open('/source/file/path', 'rb') do |file|
    #     s3.put_object(bucket: 'bucket-name', key: 'object-key', body: file)
    #   end
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     body: source_file,
    #     bucket: "BucketName", # required
    #     cache_control: "CacheControl",
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_length: 1,
    #     content_md5: "ContentMD5",
    #     content_type: "ContentType",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     expires: Time.now,
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write_acp: "GrantWriteACP",
    #     key: "ObjectKey", # required
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     server_side_encryption: "AES256", # accepts AES256, aws:kms, aws:kms:dsse
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #     website_redirect_location: "WebsiteRedirectLocation",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     ssekms_encryption_context: "SSEKMSEncryptionContext",
    #     bucket_key_enabled: false,
    #     request_payer: "requester", # accepts requester
    #     tagging: "TaggingHeader",
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_retain_until_date: Time.now,
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.expiration #=> String
    #   resp.etag #=> String
    #   resp.checksum_crc32 #=> String
    #   resp.checksum_crc32c #=> String
    #   resp.checksum_sha1 #=> String
    #   resp.checksum_sha256 #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.version_id #=> String
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.ssekms_encryption_context #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObject AWS API Documentation
    #
    # @overload put_object(params = {})
    # @param [Hash] params ({})
    def put_object(params = {}, options = {})
      req = build_request(:put_object, params)
      req.send_request(options)
    end

    # Uses the `acl` subresource to set the access control list (ACL)
    # permissions for a new or existing object in an S3 bucket. You must
    # have `WRITE_ACP` permission to set the ACL of an object. For more
    # information, see [What permissions can I grant?][1] in the *Amazon S3
    # User Guide*.
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # Depending on your application needs, you can choose to set the ACL on
    # an object using either the request body or the headers. For example,
    # if you have an existing application that updates a bucket ACL using
    # the request body, you can continue to use that approach. For more
    # information, see [Access Control List (ACL) Overview][2] in the
    # *Amazon S3 User Guide*.
    #
    # If your bucket uses the bucket owner enforced setting for S3 Object
    # Ownership, ACLs are disabled and no longer affect permissions. You
    # must use policies to grant access to your bucket and the objects in
    # it. Requests to set ACLs or update ACLs fail and return the
    # `AccessControlListNotSupported` error code. Requests to read ACLs are
    # still supported. For more information, see [Controlling object
    # ownership][3] in the *Amazon S3 User Guide*.
    #
    # Permissions
    #
    # : You can set access permissions using one of the following methods:
    #
    #   * Specify a canned ACL with the `x-amz-acl` request header. Amazon
    #     S3 supports a set of predefined ACLs, known as canned ACLs. Each
    #     canned ACL has a predefined set of grantees and permissions.
    #     Specify the canned ACL name as the value of `x-amz-ac`l. If you
    #     use this header, you cannot use other access control-specific
    #     headers in your request. For more information, see [Canned
    #     ACL][4].
    #
    #   * Specify access permissions explicitly with the `x-amz-grant-read`,
    #     `x-amz-grant-read-acp`, `x-amz-grant-write-acp`, and
    #     `x-amz-grant-full-control` headers. When using these headers, you
    #     specify explicit access permissions and grantees (Amazon Web
    #     Services accounts or Amazon S3 groups) who will receive the
    #     permission. If you use these ACL-specific headers, you cannot use
    #     `x-amz-acl` header to set a canned ACL. These parameters map to
    #     the set of permissions that Amazon S3 supports in an ACL. For more
    #     information, see [Access Control List (ACL) Overview][2].
    #
    #     You specify each grantee as a type=value pair, where the type is
    #     one of the following:
    #
    #     * `id` – if the value specified is the canonical user ID of an
    #       Amazon Web Services account
    #
    #     * `uri` – if you are granting permissions to a predefined group
    #
    #     * `emailAddress` – if the value specified is the email address of
    #       an Amazon Web Services account
    #
    #       <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #       the following Amazon Web Services Regions:
    #
    #        * US East (N. Virginia)
    #
    #       * US West (N. California)
    #
    #       * US West (Oregon)
    #
    #       * Asia Pacific (Singapore)
    #
    #       * Asia Pacific (Sydney)
    #
    #       * Asia Pacific (Tokyo)
    #
    #       * Europe (Ireland)
    #
    #       * South America (São Paulo)
    #
    #        For a list of all the Amazon S3 supported Regions and endpoints,
    #       see [Regions and Endpoints][5] in the Amazon Web Services
    #       General Reference.
    #
    #        </note>
    #
    #     For example, the following `x-amz-grant-read` header grants list
    #     objects permission to the two Amazon Web Services accounts
    #     identified by their email addresses.
    #
    #     `x-amz-grant-read: emailAddress="xyz@amazon.com",
    #     emailAddress="abc@amazon.com" `
    #
    #   You can use either a canned ACL or specify access permissions
    #   explicitly. You cannot do both.
    #
    # Grantee Values
    #
    # : You can specify the person (grantee) to whom you're assigning
    #   access rights (using request elements) in the following ways:
    #
    #   * By the person's ID:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="CanonicalUser"><ID><>ID<></ID><DisplayName><>GranteesEmail<></DisplayName>
    #     </Grantee>`
    #
    #     DisplayName is optional and ignored in the request.
    #
    #   * By URI:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="Group"><URI><>http://acs.amazonaws.com/groups/global/AuthenticatedUsers<></URI></Grantee>`
    #
    #   * By Email address:
    #
    #     `<Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    #     xsi:type="AmazonCustomerByEmail"><EmailAddress><>Grantees@email.com<></EmailAddress>lt;/Grantee>`
    #
    #     The grantee is resolved to the CanonicalUser and, in a response to
    #     a GET Object acl request, appears as the CanonicalUser.
    #
    #     <note markdown="1"> Using email addresses to specify a grantee is only supported in
    #     the following Amazon Web Services Regions:
    #
    #      * US East (N. Virginia)
    #
    #     * US West (N. California)
    #
    #     * US West (Oregon)
    #
    #     * Asia Pacific (Singapore)
    #
    #     * Asia Pacific (Sydney)
    #
    #     * Asia Pacific (Tokyo)
    #
    #     * Europe (Ireland)
    #
    #     * South America (São Paulo)
    #
    #      For a list of all the Amazon S3 supported Regions and endpoints,
    #     see [Regions and Endpoints][5] in the Amazon Web Services General
    #     Reference.
    #
    #      </note>
    #
    # Versioning
    #
    # : The ACL of an object is set at the object version level. By default,
    #   PUT sets the ACL of the current version of an object. To set the ACL
    #   of a different version, use the `versionId` subresource.
    #
    # The following operations are related to `PutObjectAcl`:
    #
    # * [CopyObject][6]
    #
    # * [GetObject][7]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#permissions
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    # [5]: https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    #
    # @option params [String] :acl
    #   The canned ACL to apply to the object. For more information, see
    #   [Canned ACL][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL
    #
    # @option params [Types::AccessControlPolicy] :access_control_policy
    #   Contains the elements that set the ACL permissions for an object per
    #   grantee.
    #
    # @option params [required, String] :bucket
    #   The bucket name that contains the object to which you want to attach
    #   the ACL.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the data. This header must be
    #   used as a message integrity check to verify that the request body was
    #   not corrupted in transit. For more information, go to [RFC
    #   1864.&gt;][1]
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    #
    #
    #   [1]: http://www.ietf.org/rfc/rfc1864.txt
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions on
    #   the bucket.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read
    #   Allows grantee to list the objects in the bucket.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_read_acp
    #   Allows grantee to read the bucket ACL.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [String] :grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    #
    # @option params [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    #
    #   This action is not supported by Amazon S3 on Outposts.
    #
    # @option params [required, String] :key
    #   Key for which the PUT action was initiated.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::PutObjectAclOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectAclOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To grant permissions using object ACL
    #
    #   # The following example adds grants to an object ACL. The first permission grants user1 and user2 FULL_CONTROL and the
    #   # AllUsers group READ permission.
    #
    #   resp = client.put_object_acl({
    #     access_control_policy: {
    #     }, 
    #     bucket: "examplebucket", 
    #     grant_full_control: "emailaddress=user1@example.com,emailaddress=user2@example.com", 
    #     grant_read: "uri=http://acs.amazonaws.com/groups/global/AllUsers", 
    #     key: "HappyFace.jpg", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object_acl({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #     access_control_policy: {
    #       grants: [
    #         {
    #           grantee: {
    #             display_name: "DisplayName",
    #             email_address: "EmailAddress",
    #             id: "ID",
    #             type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #             uri: "URI",
    #           },
    #           permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #         },
    #       ],
    #       owner: {
    #         display_name: "DisplayName",
    #         id: "ID",
    #       },
    #     },
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write: "GrantWrite",
    #     grant_write_acp: "GrantWriteACP",
    #     key: "ObjectKey", # required
    #     request_payer: "requester", # accepts requester
    #     version_id: "ObjectVersionId",
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectAcl AWS API Documentation
    #
    # @overload put_object_acl(params = {})
    # @param [Hash] params ({})
    def put_object_acl(params = {}, options = {})
      req = build_request(:put_object_acl, params)
      req.send_request(options)
    end

    # Applies a legal hold configuration to the specified object. For more
    # information, see [Locking Objects][1].
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object that you want to place a legal
    #   hold on.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [required, String] :key
    #   The key name for the object that you want to place a legal hold on.
    #
    # @option params [Types::ObjectLockLegalHold] :legal_hold
    #   Container element for the legal hold configuration you want to apply
    #   to the specified object.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :version_id
    #   The version ID of the object that you want to place a legal hold on.
    #
    # @option params [String] :content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::PutObjectLegalHoldOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectLegalHoldOutput#request_charged #request_charged} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object_legal_hold({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     legal_hold: {
    #       status: "ON", # accepts ON, OFF
    #     },
    #     request_payer: "requester", # accepts requester
    #     version_id: "ObjectVersionId",
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLegalHold AWS API Documentation
    #
    # @overload put_object_legal_hold(params = {})
    # @param [Hash] params ({})
    def put_object_legal_hold(params = {}, options = {})
      req = build_request(:put_object_legal_hold, params)
      req.send_request(options)
    end

    # Places an Object Lock configuration on the specified bucket. The rule
    # specified in the Object Lock configuration will be applied by default
    # to every new object placed in the specified bucket. For more
    # information, see [Locking Objects][1].
    #
    # <note markdown="1"> * The `DefaultRetention` settings require both a mode and a period.
    #
    # * The `DefaultRetention` period can be either `Days` or `Years` but
    #   you must select one. You cannot specify `Days` and `Years` at the
    #   same time.
    #
    # * You can only enable Object Lock for new buckets. If you want to turn
    #   on Object Lock for an existing bucket, contact Amazon Web Services
    #   Support.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #
    # @option params [required, String] :bucket
    #   The bucket whose Object Lock configuration you want to create or
    #   replace.
    #
    # @option params [Types::ObjectLockConfiguration] :object_lock_configuration
    #   The Object Lock configuration that you want to apply to the specified
    #   bucket.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :token
    #   A token to allow Object Lock to be enabled for an existing bucket.
    #
    # @option params [String] :content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::PutObjectLockConfigurationOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectLockConfigurationOutput#request_charged #request_charged} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object_lock_configuration({
    #     bucket: "BucketName", # required
    #     object_lock_configuration: {
    #       object_lock_enabled: "Enabled", # accepts Enabled
    #       rule: {
    #         default_retention: {
    #           mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #           days: 1,
    #           years: 1,
    #         },
    #       },
    #     },
    #     request_payer: "requester", # accepts requester
    #     token: "ObjectLockToken",
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectLockConfiguration AWS API Documentation
    #
    # @overload put_object_lock_configuration(params = {})
    # @param [Hash] params ({})
    def put_object_lock_configuration(params = {}, options = {})
      req = build_request(:put_object_lock_configuration, params)
      req.send_request(options)
    end

    # Places an Object Retention configuration on an object. For more
    # information, see [Locking Objects][1]. Users or accounts require the
    # `s3:PutObjectRetention` permission in order to place an Object
    # Retention configuration on objects. Bypassing a Governance Retention
    # configuration requires the `s3:BypassGovernanceRetention` permission.
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html
    #
    # @option params [required, String] :bucket
    #   The bucket name that contains the object you want to apply this Object
    #   Retention configuration to.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #
    # @option params [required, String] :key
    #   The key name for the object that you want to apply this Object
    #   Retention configuration to.
    #
    # @option params [Types::ObjectLockRetention] :retention
    #   The container element for the Object Retention configuration.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :version_id
    #   The version ID for the object that you want to apply this Object
    #   Retention configuration to.
    #
    # @option params [Boolean] :bypass_governance_retention
    #   Indicates whether this action should bypass Governance-mode
    #   restrictions.
    #
    # @option params [String] :content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::PutObjectRetentionOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectRetentionOutput#request_charged #request_charged} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object_retention({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     retention: {
    #       mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #       retain_until_date: Time.now,
    #     },
    #     request_payer: "requester", # accepts requester
    #     version_id: "ObjectVersionId",
    #     bypass_governance_retention: false,
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectRetention AWS API Documentation
    #
    # @overload put_object_retention(params = {})
    # @param [Hash] params ({})
    def put_object_retention(params = {}, options = {})
      req = build_request(:put_object_retention, params)
      req.send_request(options)
    end

    # Sets the supplied tag-set to an object that already exists in a
    # bucket.
    #
    # A tag is a key-value pair. You can associate tags with an object by
    # sending a PUT request against the tagging subresource that is
    # associated with the object. You can retrieve tags by sending a GET
    # request. For more information, see [GetObjectTagging][1].
    #
    # For tagging-related restrictions related to characters and encodings,
    # see [Tag Restrictions][2]. Note that Amazon S3 limits the maximum
    # number of tags to 10 tags per object.
    #
    # To use this operation, you must have permission to perform the
    # `s3:PutObjectTagging` action. By default, the bucket owner has this
    # permission and can grant this permission to others.
    #
    # To put tags of any other version, use the `versionId` query parameter.
    # You also need permission for the `s3:PutObjectVersionTagging` action.
    #
    # For information about the Amazon S3 object tagging feature, see
    # [Object Tagging][3].
    #
    # `PutObjectTagging` has the following special errors:
    #
    # * * <i>Code: InvalidTagError </i>
    #
    #   * *Cause: The tag provided was not a valid tag. This error can occur
    #     if the tag did not pass input validation. For more information,
    #     see [Object Tagging][3].*
    #
    # * * <i>Code: MalformedXMLError </i>
    #
    #   * *Cause: The XML provided does not match the schema.*
    #
    # * * <i>Code: OperationAbortedError </i>
    #
    #   * *Cause: A conflicting conditional action is currently in progress
    #     against this resource. Please try again.*
    #
    # * * *Code: InternalError*
    #
    #   * *Cause: The service was unable to apply the provided tag to the
    #     object.*
    #
    # The following operations are related to `PutObjectTagging`:
    #
    # * [GetObjectTagging][1]
    #
    # * [DeleteObjectTagging][4]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObjectTagging.html
    # [2]: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-tagging.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjectTagging.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Name of the object key.
    #
    # @option params [String] :version_id
    #   The versionId of the object that the tag-set will be added to.
    #
    # @option params [String] :content_md5
    #   The MD5 hash for the request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::Tagging] :tagging
    #   Container for the `TagSet` and `Tag` elements
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @return [Types::PutObjectTaggingOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::PutObjectTaggingOutput#version_id #version_id} => String
    #
    #
    # @example Example: To add tags to an existing object
    #
    #   # The following example adds tags to an existing object.
    #
    #   resp = client.put_object_tagging({
    #     bucket: "examplebucket", 
    #     key: "HappyFace.jpg", 
    #     tagging: {
    #       tag_set: [
    #         {
    #           key: "Key3", 
    #           value: "Value3", 
    #         }, 
    #         {
    #           key: "Key4", 
    #           value: "Value4", 
    #         }, 
    #       ], 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     version_id: "null", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_object_tagging({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     tagging: { # required
    #       tag_set: [ # required
    #         {
    #           key: "ObjectKey", # required
    #           value: "Value", # required
    #         },
    #       ],
    #     },
    #     expected_bucket_owner: "AccountId",
    #     request_payer: "requester", # accepts requester
    #   })
    #
    # @example Response structure
    #
    #   resp.version_id #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutObjectTagging AWS API Documentation
    #
    # @overload put_object_tagging(params = {})
    # @param [Hash] params ({})
    def put_object_tagging(params = {}, options = {})
      req = build_request(:put_object_tagging, params)
      req.send_request(options)
    end

    # Creates or modifies the `PublicAccessBlock` configuration for an
    # Amazon S3 bucket. To use this operation, you must have the
    # `s3:PutBucketPublicAccessBlock` permission. For more information about
    # Amazon S3 permissions, see [Specifying Permissions in a Policy][1].
    #
    # When Amazon S3 evaluates the `PublicAccessBlock` configuration for a
    # bucket or an object, it checks the `PublicAccessBlock` configuration
    # for both the bucket (or the bucket that contains the object) and the
    # bucket owner's account. If the `PublicAccessBlock` configurations are
    # different between the bucket and the account, Amazon S3 uses the most
    # restrictive combination of the bucket-level and account-level
    # settings.
    #
    # For more information about when Amazon S3 considers a bucket or an
    # object public, see [The Meaning of "Public"][2].
    #
    # The following operations are related to `PutPublicAccessBlock`:
    #
    # * [GetPublicAccessBlock][3]
    #
    # * [DeletePublicAccessBlock][4]
    #
    # * [GetBucketPolicyStatus][5]
    #
    # * [Using Amazon S3 Block Public Access][6]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetPublicAccessBlock.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeletePublicAccessBlock.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketPolicyStatus.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html
    #
    # @option params [required, String] :bucket
    #   The name of the Amazon S3 bucket whose `PublicAccessBlock`
    #   configuration you want to set.
    #
    # @option params [String] :content_md5
    #   The MD5 hash of the `PutPublicAccessBlock` request body.
    #
    #   For requests made using the Amazon Web Services Command Line Interface
    #   (CLI) or Amazon Web Services SDKs, this field is calculated
    #   automatically.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, Types::PublicAccessBlockConfiguration] :public_access_block_configuration
    #   The `PublicAccessBlock` configuration that you want to apply to this
    #   Amazon S3 bucket. You can enable the configuration options in any
    #   combination. For more information about when Amazon S3 considers a
    #   bucket or object public, see [The Meaning of "Public"][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/access-control-block-public-access.html#access-control-block-public-access-policy-status
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.put_public_access_block({
    #     bucket: "BucketName", # required
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     public_access_block_configuration: { # required
    #       block_public_acls: false,
    #       ignore_public_acls: false,
    #       block_public_policy: false,
    #       restrict_public_buckets: false,
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/PutPublicAccessBlock AWS API Documentation
    #
    # @overload put_public_access_block(params = {})
    # @param [Hash] params ({})
    def put_public_access_block(params = {}, options = {})
      req = build_request(:put_public_access_block, params)
      req.send_request(options)
    end

    # Restores an archived copy of an object back into Amazon S3
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # This action performs the following types of requests:
    #
    # * `select` - Perform a select query on an archived object
    #
    # * `restore an archive` - Restore an archived object
    #
    # For more information about the `S3` structure in the request body, see
    # the following:
    #
    # * [PutObject][1]
    #
    # * [Managing Access with ACLs][2] in the *Amazon S3 User Guide*
    #
    # * [Protecting Data Using Server-Side Encryption][3] in the *Amazon S3
    #   User Guide*
    #
    # Define the SQL expression for the `SELECT` type of restoration for
    # your query in the request body's `SelectParameters` structure. You
    # can use expressions like the following examples.
    #
    # * The following expression returns all records from the specified
    #   object.
    #
    #   `SELECT * FROM Object`
    #
    # * Assuming that you are not using any headers for data stored in the
    #   object, you can specify columns with positional headers.
    #
    #   `SELECT s._1, s._2 FROM Object s WHERE s._3 > 100`
    #
    # * If you have headers and you set the `fileHeaderInfo` in the `CSV`
    #   structure in the request body to `USE`, you can specify headers in
    #   the query. (If you set the `fileHeaderInfo` field to `IGNORE`, the
    #   first row is skipped for the query.) You cannot mix ordinal
    #   positions with header column names.
    #
    #   `SELECT s.Id, s.FirstName, s.SSN FROM S3Object s`
    #
    # When making a select request, you can also do the following:
    #
    # * To expedite your queries, specify the `Expedited` tier. For more
    #   information about tiers, see "Restoring Archives," later in this
    #   topic.
    #
    # * Specify details about the data serialization format of both the
    #   input object that is being queried and the serialization of the
    #   CSV-encoded query results.
    #
    # The following are additional important facts about the select feature:
    #
    # * The output results are new Amazon S3 objects. Unlike archive
    #   retrievals, they are stored until explicitly deleted-manually or
    #   through a lifecycle configuration.
    #
    # * You can issue more than one select request on the same Amazon S3
    #   object. Amazon S3 doesn't duplicate requests, so avoid issuing
    #   duplicate requests.
    #
    # * Amazon S3 accepts a select request even if the object has already
    #   been restored. A select request doesn’t return error response `409`.
    #
    # Permissions
    #
    # : To use this operation, you must have permissions to perform the
    #   `s3:RestoreObject` action. The bucket owner has this permission by
    #   default and can grant this permission to others. For more
    #   information about permissions, see [Permissions Related to Bucket
    #   Subresource Operations][4] and [Managing Access Permissions to Your
    #   Amazon S3 Resources][5] in the *Amazon S3 User Guide*.
    #
    # Restoring objects
    #
    # : Objects that you archive to the S3 Glacier Flexible Retrieval
    #   Flexible Retrieval or S3 Glacier Deep Archive storage class, and S3
    #   Intelligent-Tiering Archive or S3 Intelligent-Tiering Deep Archive
    #   tiers, are not accessible in real time. For objects in the S3
    #   Glacier Flexible Retrieval Flexible Retrieval or S3 Glacier Deep
    #   Archive storage classes, you must first initiate a restore request,
    #   and then wait until a temporary copy of the object is available. If
    #   you want a permanent copy of the object, create a copy of it in the
    #   Amazon S3 Standard storage class in your S3 bucket. To access an
    #   archived object, you must restore the object for the duration
    #   (number of days) that you specify. For objects in the Archive Access
    #   or Deep Archive Access tiers of S3 Intelligent-Tiering, you must
    #   first initiate a restore request, and then wait until the object is
    #   moved into the Frequent Access tier.
    #
    #   To restore a specific object version, you can provide a version ID.
    #   If you don't provide a version ID, Amazon S3 restores the current
    #   version.
    #
    #   When restoring an archived object, you can specify one of the
    #   following data access tier options in the `Tier` element of the
    #   request body:
    #
    #   * `Expedited` - Expedited retrievals allow you to quickly access
    #     your data stored in the S3 Glacier Flexible Retrieval Flexible
    #     Retrieval storage class or S3 Intelligent-Tiering Archive tier
    #     when occasional urgent requests for restoring archives are
    #     required. For all but the largest archived objects (250 MB+), data
    #     accessed using Expedited retrievals is typically made available
    #     within 1–5 minutes. Provisioned capacity ensures that retrieval
    #     capacity for Expedited retrievals is available when you need it.
    #     Expedited retrievals and provisioned capacity are not available
    #     for objects stored in the S3 Glacier Deep Archive storage class or
    #     S3 Intelligent-Tiering Deep Archive tier.
    #
    #   * `Standard` - Standard retrievals allow you to access any of your
    #     archived objects within several hours. This is the default option
    #     for retrieval requests that do not specify the retrieval option.
    #     Standard retrievals typically finish within 3–5 hours for objects
    #     stored in the S3 Glacier Flexible Retrieval Flexible Retrieval
    #     storage class or S3 Intelligent-Tiering Archive tier. They
    #     typically finish within 12 hours for objects stored in the S3
    #     Glacier Deep Archive storage class or S3 Intelligent-Tiering Deep
    #     Archive tier. Standard retrievals are free for objects stored in
    #     S3 Intelligent-Tiering.
    #
    #   * `Bulk` - Bulk retrievals free for objects stored in the S3 Glacier
    #     Flexible Retrieval and S3 Intelligent-Tiering storage classes,
    #     enabling you to retrieve large amounts, even petabytes, of data at
    #     no cost. Bulk retrievals typically finish within 5–12 hours for
    #     objects stored in the S3 Glacier Flexible Retrieval Flexible
    #     Retrieval storage class or S3 Intelligent-Tiering Archive tier.
    #     Bulk retrievals are also the lowest-cost retrieval option when
    #     restoring objects from S3 Glacier Deep Archive. They typically
    #     finish within 48 hours for objects stored in the S3 Glacier Deep
    #     Archive storage class or S3 Intelligent-Tiering Deep Archive tier.
    #
    #   For more information about archive retrieval options and provisioned
    #   capacity for `Expedited` data access, see [Restoring Archived
    #   Objects][6] in the *Amazon S3 User Guide*.
    #
    #   You can use Amazon S3 restore speed upgrade to change the restore
    #   speed to a faster speed while it is in progress. For more
    #   information, see [ Upgrading the speed of an in-progress restore][7]
    #   in the *Amazon S3 User Guide*.
    #
    #   To get the status of object restoration, you can send a `HEAD`
    #   request. Operations return the `x-amz-restore` header, which
    #   provides information about the restoration status, in the response.
    #   You can use Amazon S3 event notifications to notify you when a
    #   restore is initiated or completed. For more information, see
    #   [Configuring Amazon S3 Event Notifications][8] in the *Amazon S3
    #   User Guide*.
    #
    #   After restoring an archived object, you can update the restoration
    #   period by reissuing the request with a new period. Amazon S3 updates
    #   the restoration period relative to the current time and charges only
    #   for the request-there are no data transfer charges. You cannot
    #   update the restoration period when Amazon S3 is actively processing
    #   your current restore request for the object.
    #
    #   If your bucket has a lifecycle configuration with a rule that
    #   includes an expiration action, the object expiration overrides the
    #   life span that you specify in a restore request. For example, if you
    #   restore an object copy for 10 days, but the object is scheduled to
    #   expire in 3 days, Amazon S3 deletes the object in 3 days. For more
    #   information about lifecycle configuration, see
    #   [PutBucketLifecycleConfiguration][9] and [Object Lifecycle
    #   Management][10] in *Amazon S3 User Guide*.
    #
    # Responses
    #
    # : A successful action returns either the `200 OK` or `202 Accepted`
    #   status code.
    #
    #   * If the object is not previously restored, then Amazon S3 returns
    #     `202 Accepted` in the response.
    #
    #   * If the object is previously restored, Amazon S3 returns `200 OK`
    #     in the response.
    #   ^
    #
    #   * Special errors:
    #
    #     * *Code: RestoreAlreadyInProgress*
    #
    #     * *Cause: Object restore is already in progress. (This error does
    #       not apply to SELECT type requests.)*
    #
    #     * *HTTP Status Code: 409 Conflict*
    #
    #     * *SOAP Fault Code Prefix: Client*
    #
    #   * * *Code: GlacierExpeditedRetrievalNotAvailable*
    #
    #     * *Cause: expedited retrievals are currently not available. Try
    #       again later. (Returned if there is insufficient capacity to
    #       process the Expedited request. This error applies only to
    #       Expedited retrievals and not to S3 Standard or Bulk
    #       retrievals.)*
    #
    #     * *HTTP Status Code: 503*
    #
    #     * *SOAP Fault Code Prefix: N/A*
    #
    # The following operations are related to `RestoreObject`:
    #
    # * [PutBucketLifecycleConfiguration][9]
    #
    # * [GetBucketNotificationConfiguration][11]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/dev/S3_ACLs_UsingACLs.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-with-s3-actions.html#using-with-s3-actions-related-to-bucket-subresources
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-access-control.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/dev/restoring-objects.html#restoring-objects-upgrade-tier.title.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketNotificationConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The bucket name containing the object to restore.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :key
    #   Object key for which the action was initiated.
    #
    # @option params [String] :version_id
    #   VersionId used to reference a specific version of the object.
    #
    # @option params [Types::RestoreRequest] :restore_request
    #   Container for restore job parameters.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::RestoreObjectOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::RestoreObjectOutput#request_charged #request_charged} => String
    #   * {Types::RestoreObjectOutput#restore_output_path #restore_output_path} => String
    #
    #
    # @example Example: To restore an archived object
    #
    #   # The following example restores for one day an archived copy of an object back into Amazon S3 bucket.
    #
    #   resp = client.restore_object({
    #     bucket: "examplebucket", 
    #     key: "archivedobjectkey", 
    #     restore_request: {
    #       days: 1, 
    #       glacier_job_parameters: {
    #         tier: "Expedited", 
    #       }, 
    #     }, 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.restore_object({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     version_id: "ObjectVersionId",
    #     restore_request: {
    #       days: 1,
    #       glacier_job_parameters: {
    #         tier: "Standard", # required, accepts Standard, Bulk, Expedited
    #       },
    #       type: "SELECT", # accepts SELECT
    #       tier: "Standard", # accepts Standard, Bulk, Expedited
    #       description: "Description",
    #       select_parameters: {
    #         input_serialization: { # required
    #           csv: {
    #             file_header_info: "USE", # accepts USE, IGNORE, NONE
    #             comments: "Comments",
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #             allow_quoted_record_delimiter: false,
    #           },
    #           compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #           json: {
    #             type: "DOCUMENT", # accepts DOCUMENT, LINES
    #           },
    #           parquet: {
    #           },
    #         },
    #         expression_type: "SQL", # required, accepts SQL
    #         expression: "Expression", # required
    #         output_serialization: { # required
    #           csv: {
    #             quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #             quote_escape_character: "QuoteEscapeCharacter",
    #             record_delimiter: "RecordDelimiter",
    #             field_delimiter: "FieldDelimiter",
    #             quote_character: "QuoteCharacter",
    #           },
    #           json: {
    #             record_delimiter: "RecordDelimiter",
    #           },
    #         },
    #       },
    #       output_location: {
    #         s3: {
    #           bucket_name: "BucketName", # required
    #           prefix: "LocationPrefix", # required
    #           encryption: {
    #             encryption_type: "AES256", # required, accepts AES256, aws:kms, aws:kms:dsse
    #             kms_key_id: "SSEKMSKeyId",
    #             kms_context: "KMSContext",
    #           },
    #           canned_acl: "private", # accepts private, public-read, public-read-write, authenticated-read, aws-exec-read, bucket-owner-read, bucket-owner-full-control
    #           access_control_list: [
    #             {
    #               grantee: {
    #                 display_name: "DisplayName",
    #                 email_address: "EmailAddress",
    #                 id: "ID",
    #                 type: "CanonicalUser", # required, accepts CanonicalUser, AmazonCustomerByEmail, Group
    #                 uri: "URI",
    #               },
    #               permission: "FULL_CONTROL", # accepts FULL_CONTROL, WRITE, WRITE_ACP, READ, READ_ACP
    #             },
    #           ],
    #           tagging: {
    #             tag_set: [ # required
    #               {
    #                 key: "ObjectKey", # required
    #                 value: "Value", # required
    #               },
    #             ],
    #           },
    #           user_metadata: [
    #             {
    #               name: "MetadataKey",
    #               value: "MetadataValue",
    #             },
    #           ],
    #           storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #         },
    #       },
    #     },
    #     request_payer: "requester", # accepts requester
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.request_charged #=> String, one of "requester"
    #   resp.restore_output_path #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/RestoreObject AWS API Documentation
    #
    # @overload restore_object(params = {})
    # @param [Hash] params ({})
    def restore_object(params = {}, options = {})
      req = build_request(:restore_object, params)
      req.send_request(options)
    end

    # This action filters the contents of an Amazon S3 object based on a
    # simple structured query language (SQL) statement. In the request,
    # along with the SQL expression, you must also specify a data
    # serialization format (JSON, CSV, or Apache Parquet) of the object.
    # Amazon S3 uses this format to parse object data into records, and
    # returns only records that match the specified SQL expression. You must
    # also specify the data serialization format for the response.
    #
    # This action is not supported by Amazon S3 on Outposts.
    #
    # For more information about Amazon S3 Select, see [Selecting Content
    # from Objects][1] and [SELECT Command][2] in the *Amazon S3 User
    # Guide*.
    #
    #
    #
    # Permissions
    #
    # : You must have `s3:GetObject` permission for this operation. Amazon
    #   S3 Select does not support anonymous access. For more information
    #   about permissions, see [Specifying Permissions in a Policy][3] in
    #   the *Amazon S3 User Guide*.
    #
    # Object Data Formats
    #
    # : You can use Amazon S3 Select to query objects that have the
    #   following format properties:
    #
    #   * *CSV, JSON, and Parquet* - Objects must be in CSV, JSON, or
    #     Parquet format.
    #
    #   * *UTF-8* - UTF-8 is the only encoding type Amazon S3 Select
    #     supports.
    #
    #   * *GZIP or BZIP2* - CSV and JSON files can be compressed using GZIP
    #     or BZIP2. GZIP and BZIP2 are the only compression formats that
    #     Amazon S3 Select supports for CSV and JSON files. Amazon S3 Select
    #     supports columnar compression for Parquet using GZIP or Snappy.
    #     Amazon S3 Select does not support whole-object compression for
    #     Parquet objects.
    #
    #   * *Server-side encryption* - Amazon S3 Select supports querying
    #     objects that are protected with server-side encryption.
    #
    #     For objects that are encrypted with customer-provided encryption
    #     keys (SSE-C), you must use HTTPS, and you must use the headers
    #     that are documented in the [GetObject][4]. For more information
    #     about SSE-C, see [Server-Side Encryption (Using Customer-Provided
    #     Encryption Keys)][5] in the *Amazon S3 User Guide*.
    #
    #     For objects that are encrypted with Amazon S3 managed keys
    #     (SSE-S3) and Amazon Web Services KMS keys (SSE-KMS), server-side
    #     encryption is handled transparently, so you don't need to specify
    #     anything. For more information about server-side encryption,
    #     including SSE-S3 and SSE-KMS, see [Protecting Data Using
    #     Server-Side Encryption][6] in the *Amazon S3 User Guide*.
    #
    # Working with the Response Body
    #
    # : Given the response size is unknown, Amazon S3 Select streams the
    #   response as a series of messages and includes a `Transfer-Encoding`
    #   header with `chunked` as its value in the response. For more
    #   information, see [Appendix: SelectObjectContent Response][7].
    #
    # GetObject Support
    #
    # : The `SelectObjectContent` action does not support the following
    #   `GetObject` functionality. For more information, see [GetObject][4].
    #
    #   * `Range`: Although you can specify a scan range for an Amazon S3
    #     Select request (see [SelectObjectContentRequest - ScanRange][8] in
    #     the request parameters), you cannot specify the range of bytes of
    #     an object to return.
    #
    #   * The `GLACIER`, `DEEP_ARCHIVE`, and `REDUCED_REDUNDANCY` storage
    #     classes, or the `ARCHIVE_ACCESS` and `DEEP_ARCHIVE_ACCESS` access
    #     tiers of the `INTELLIGENT_TIERING` storage class: You cannot query
    #     objects in the `GLACIER`, `DEEP_ARCHIVE`, or `REDUCED_REDUNDANCY`
    #     storage classes, nor objects in the `ARCHIVE_ACCESS` or
    #     `DEEP_ARCHIVE_ACCESS` access tiers of the `INTELLIGENT_TIERING`
    #     storage class. For more information about storage classes, see
    #     [Using Amazon S3 storage classes][9] in the *Amazon S3 User
    #     Guide*.
    #
    # Special Errors
    #
    # : For a list of special errors for this operation, see [List of SELECT
    #   Object Content Error Codes][10]
    #
    # The following operations are related to `SelectObjectContent`:
    #
    # * [GetObject][4]
    #
    # * [GetBucketLifecycleConfiguration][11]
    #
    # * [PutBucketLifecycleConfiguration][12]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/selecting-content-from-objects.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-glacier-select-sql-reference-select.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/using-with-s3-actions.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/serv-side-encryption.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/RESTSelectObjectAppendix.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_SelectObjectContent.html#AmazonS3-SelectObjectContent-request-ScanRange
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html#SelectObjectContentErrorCodeList
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLifecycleConfiguration.html
    # [12]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html
    #
    # @option params [required, String] :bucket
    #   The S3 bucket.
    #
    # @option params [required, String] :key
    #   The object key.
    #
    # @option params [String] :sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the object.
    #   This parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This parameter
    #   is needed only when the object was created using a checksum algorithm.
    #   For more information, see [Protecting data using SSE-C keys][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a checksum
    #   algorithm. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [required, String] :expression
    #   The expression that is used to query the object.
    #
    # @option params [required, String] :expression_type
    #   The type of the provided expression (for example, SQL).
    #
    # @option params [Types::RequestProgress] :request_progress
    #   Specifies if periodic request progress information should be enabled.
    #
    # @option params [required, Types::InputSerialization] :input_serialization
    #   Describes the format of the data in the object that is being queried.
    #
    # @option params [required, Types::OutputSerialization] :output_serialization
    #   Describes the format of the data that you want Amazon S3 to return in
    #   response.
    #
    # @option params [Types::ScanRange] :scan_range
    #   Specifies the byte range of the object to get the records from. A
    #   record is processed when its first byte is contained by the range.
    #   This parameter is optional, but when specified, it must not be empty.
    #   See RFC 2616, Section 14.35.1 about how to specify the start and end
    #   of the range.
    #
    #   `ScanRange`may be used in the following ways:
    #
    #   * `<scanrange><start>50</start><end>100</end></scanrange>` - process
    #     only the records starting between the bytes 50 and 100 (inclusive,
    #     counting from zero)
    #
    #   * `<scanrange><start>50</start></scanrange>` - process only the
    #     records starting after the byte 50
    #
    #   * `<scanrange><end>50</end></scanrange>` - process only the records
    #     within the last 50 bytes of the file.
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::SelectObjectContentOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::SelectObjectContentOutput#payload #payload} => Types::SelectObjectContentEventStream
    #
    # @example EventStream Operation Example
    #
    #   You can process event once it arrives immediately, or wait until
    #   full response complete and iterate through eventstream enumerator.
    #
    #   To interact with event immediately, you need to register #select_object_content
    #   with callbacks, callbacks can be register for specifc events or for all events,
    #   callback for errors in the event stream is also available for register.
    #
    #   Callbacks can be passed in by `:event_stream_handler` option or within block
    #   statement attached to #select_object_content call directly. Hybrid pattern of both
    #   is also supported.
    #
    #   `:event_stream_handler` option takes in either Proc object or
    #   Aws::S3::EventStreams::SelectObjectContentEventStream object.
    #
    #   Usage pattern a): callbacks with a block attached to #select_object_content
    #     Example for registering callbacks for all event types and error event
    #
    #     client.select_object_content( # params input# ) do |stream|
    #       stream.on_error_event do |event|
    #         # catch unmodeled error event in the stream
    #         raise event
    #         # => Aws::Errors::EventError
    #         # event.event_type => :error
    #         # event.error_code => String
    #         # event.error_message => String
    #       end
    #
    #       stream.on_event do |event|
    #         # process all events arrive
    #         puts event.event_type
    #         ...
    #       end
    #
    #     end
    #
    #   Usage pattern b): pass in `:event_stream_handler` for #select_object_content
    #
    #     1) create a Aws::S3::EventStreams::SelectObjectContentEventStream object
    #     Example for registering callbacks with specific events
    #
    #       handler = Aws::S3::EventStreams::SelectObjectContentEventStream.new
    #       handler.on_records_event do |event|
    #         event # => Aws::S3::Types::Records
    #       end
    #       handler.on_stats_event do |event|
    #         event # => Aws::S3::Types::Stats
    #       end
    #       handler.on_progress_event do |event|
    #         event # => Aws::S3::Types::Progress
    #       end
    #       handler.on_cont_event do |event|
    #         event # => Aws::S3::Types::Cont
    #       end
    #       handler.on_end_event do |event|
    #         event # => Aws::S3::Types::End
    #       end
    #
    #     client.select_object_content( # params input #, event_stream_handler: handler)
    #
    #     2) use a Ruby Proc object
    #     Example for registering callbacks with specific events
    #
    #     handler = Proc.new do |stream|
    #       stream.on_records_event do |event|
    #         event # => Aws::S3::Types::Records
    #       end
    #       stream.on_stats_event do |event|
    #         event # => Aws::S3::Types::Stats
    #       end
    #       stream.on_progress_event do |event|
    #         event # => Aws::S3::Types::Progress
    #       end
    #       stream.on_cont_event do |event|
    #         event # => Aws::S3::Types::Cont
    #       end
    #       stream.on_end_event do |event|
    #         event # => Aws::S3::Types::End
    #       end
    #     end
    #
    #     client.select_object_content( # params input #, event_stream_handler: handler)
    #
    #   Usage pattern c): hybird pattern of a) and b)
    #
    #       handler = Aws::S3::EventStreams::SelectObjectContentEventStream.new
    #       handler.on_records_event do |event|
    #         event # => Aws::S3::Types::Records
    #       end
    #       handler.on_stats_event do |event|
    #         event # => Aws::S3::Types::Stats
    #       end
    #       handler.on_progress_event do |event|
    #         event # => Aws::S3::Types::Progress
    #       end
    #       handler.on_cont_event do |event|
    #         event # => Aws::S3::Types::Cont
    #       end
    #       handler.on_end_event do |event|
    #         event # => Aws::S3::Types::End
    #       end
    #
    #     client.select_object_content( # params input #, event_stream_handler: handler) do |stream|
    #       stream.on_error_event do |event|
    #         # catch unmodeled error event in the stream
    #         raise event
    #         # => Aws::Errors::EventError
    #         # event.event_type => :error
    #         # event.error_code => String
    #         # event.error_message => String
    #       end
    #     end
    #
    #   Besides above usage patterns for process events when they arrive immediately, you can also
    #   iterate through events after response complete.
    #
    #   Events are available at resp.payload # => Enumerator
    #   For parameter input example, please refer to following request syntax
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.select_object_content({
    #     bucket: "BucketName", # required
    #     key: "ObjectKey", # required
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     expression: "Expression", # required
    #     expression_type: "SQL", # required, accepts SQL
    #     request_progress: {
    #       enabled: false,
    #     },
    #     input_serialization: { # required
    #       csv: {
    #         file_header_info: "USE", # accepts USE, IGNORE, NONE
    #         comments: "Comments",
    #         quote_escape_character: "QuoteEscapeCharacter",
    #         record_delimiter: "RecordDelimiter",
    #         field_delimiter: "FieldDelimiter",
    #         quote_character: "QuoteCharacter",
    #         allow_quoted_record_delimiter: false,
    #       },
    #       compression_type: "NONE", # accepts NONE, GZIP, BZIP2
    #       json: {
    #         type: "DOCUMENT", # accepts DOCUMENT, LINES
    #       },
    #       parquet: {
    #       },
    #     },
    #     output_serialization: { # required
    #       csv: {
    #         quote_fields: "ALWAYS", # accepts ALWAYS, ASNEEDED
    #         quote_escape_character: "QuoteEscapeCharacter",
    #         record_delimiter: "RecordDelimiter",
    #         field_delimiter: "FieldDelimiter",
    #         quote_character: "QuoteCharacter",
    #       },
    #       json: {
    #         record_delimiter: "RecordDelimiter",
    #       },
    #     },
    #     scan_range: {
    #       start: 1,
    #       end: 1,
    #     },
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   All events are available at resp.payload:
    #   resp.payload #=> Enumerator
    #   resp.payload.event_types #=> [:records, :stats, :progress, :cont, :end]
    #
    #   For :records event available at #on_records_event callback and response eventstream enumerator:
    #   event.payload #=> IO
    #
    #   For :stats event available at #on_stats_event callback and response eventstream enumerator:
    #   event.details.bytes_scanned #=> Integer
    #   event.details.bytes_processed #=> Integer
    #   event.details.bytes_returned #=> Integer
    #
    #   For :progress event available at #on_progress_event callback and response eventstream enumerator:
    #   event.details.bytes_scanned #=> Integer
    #   event.details.bytes_processed #=> Integer
    #   event.details.bytes_returned #=> Integer
    #
    #   For :cont event available at #on_cont_event callback and response eventstream enumerator:
    #    #=> EmptyStruct
    #   For :end event available at #on_end_event callback and response eventstream enumerator:
    #    #=> EmptyStruct
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/SelectObjectContent AWS API Documentation
    #
    # @overload select_object_content(params = {})
    # @param [Hash] params ({})
    def select_object_content(params = {}, options = {}, &block)
      params = params.dup
      event_stream_handler = case handler = params.delete(:event_stream_handler)
        when EventStreams::SelectObjectContentEventStream then handler
        when Proc then EventStreams::SelectObjectContentEventStream.new.tap(&handler)
        when nil then EventStreams::SelectObjectContentEventStream.new
        else
          msg = "expected :event_stream_handler to be a block or "\
                "instance of Aws::S3::EventStreams::SelectObjectContentEventStream"\
                ", got `#{handler.inspect}` instead"
          raise ArgumentError, msg
        end

      yield(event_stream_handler) if block_given?

      req = build_request(:select_object_content, params)

      req.context[:event_stream_handler] = event_stream_handler
      req.handlers.add(Aws::Binary::DecodeHandler, priority: 95)

      req.send_request(options, &block)
    end

    # Uploads a part in a multipart upload.
    #
    # <note markdown="1"> In this operation, you provide part data in your request. However, you
    # have an option to specify your existing Amazon S3 object as a data
    # source for the part you are uploading. To upload a part from an
    # existing object, you use the [UploadPartCopy][1] operation.
    #
    #  </note>
    #
    # You must initiate a multipart upload (see [CreateMultipartUpload][2])
    # before you can upload any part. In response to your initiate request,
    # Amazon S3 returns an upload ID, a unique identifier, that you must
    # include in your upload part request.
    #
    # Part numbers can be any number from 1 to 10,000, inclusive. A part
    # number uniquely identifies a part and also defines its position within
    # the object being created. If you upload a new part using the same part
    # number that was used with a previous part, the previously uploaded
    # part is overwritten.
    #
    # For information about maximum and minimum part sizes and other
    # multipart upload specifications, see [Multipart upload limits][3] in
    # the *Amazon S3 User Guide*.
    #
    # To ensure that data is not corrupted when traversing the network,
    # specify the `Content-MD5` header in the upload part request. Amazon S3
    # checks the part data against the provided MD5 value. If they do not
    # match, Amazon S3 returns an error.
    #
    # If the upload request is signed with Signature Version 4, then Amazon
    # Web Services S3 uses the `x-amz-content-sha256` header as a checksum
    # instead of `Content-MD5`. For more information see [Authenticating
    # Requests: Using the Authorization Header (Amazon Web Services
    # Signature Version 4)][4].
    #
    # **Note:** After you initiate multipart upload and upload one or more
    # parts, you must either complete or abort multipart upload in order to
    # stop getting charged for storage of the uploaded parts. Only after you
    # either complete or abort multipart upload, Amazon S3 frees up the
    # parts storage and stops charging you for the parts storage.
    #
    # For more information on multipart uploads, go to [Multipart Upload
    # Overview][5] in the <i>Amazon S3 User Guide </i>.
    #
    # For information on the permissions required to use the multipart
    # upload API, go to [Multipart Upload and Permissions][6] in the *Amazon
    # S3 User Guide*.
    #
    # Server-side encryption is for data encryption at rest. Amazon S3
    # encrypts your data as it writes it to disks in its data centers and
    # decrypts it when you access it. You have three mutually exclusive
    # options to protect data using server-side encryption in Amazon S3,
    # depending on how you choose to manage the encryption keys.
    # Specifically, the encryption key options are Amazon S3 managed keys
    # (SSE-S3), Amazon Web Services KMS keys (SSE-KMS), and
    # Customer-Provided Keys (SSE-C). Amazon S3 encrypts data with
    # server-side encryption using Amazon S3 managed keys (SSE-S3) by
    # default. You can optionally tell Amazon S3 to encrypt data at rest
    # using server-side encryption with other key options. The option you
    # use depends on whether you want to use KMS keys (SSE-KMS) or provide
    # your own encryption key (SSE-C). If you choose to provide your own
    # encryption key, the request headers you provide in the request must
    # match the headers you used in the request to initiate the upload by
    # using [CreateMultipartUpload][2]. For more information, go to [Using
    # Server-Side Encryption][7] in the *Amazon S3 User Guide*.
    #
    # Server-side encryption is supported by the S3 Multipart Upload
    # actions. Unless you are using a customer-provided encryption key
    # (SSE-C), you don't need to specify the encryption parameters in each
    # UploadPart request. Instead, you only need to specify the server-side
    # encryption parameters in the initial Initiate Multipart request. For
    # more information, see [CreateMultipartUpload][2].
    #
    # If you requested server-side encryption using a customer-provided
    # encryption key (SSE-C) in your initiate multipart upload request, you
    # must provide identical encryption information in each part upload
    # using the following headers.
    #
    # * x-amz-server-side-encryption-customer-algorithm
    #
    # * x-amz-server-side-encryption-customer-key
    #
    # * x-amz-server-side-encryption-customer-key-MD5
    #
    # `UploadPart` has the following special errors:
    #
    # * * *Code: NoSuchUpload*
    #
    #   * *Cause: The specified multipart upload does not exist. The upload
    #     ID might be invalid, or the multipart upload might have been
    #     aborted or completed.*
    #
    #   * <i> HTTP Status Code: 404 Not Found </i>
    #
    #   * *SOAP Fault Code Prefix: Client*
    #
    # The following operations are related to `UploadPart`:
    #
    # * [CreateMultipartUpload][2]
    #
    # * [CompleteMultipartUpload][8]
    #
    # * [AbortMultipartUpload][9]
    #
    # * [ListParts][10]
    #
    # * [ListMultipartUploads][11]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-auth-using-authorization-header.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingServerSideEncryption.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [String, StringIO, File] :body
    #   Object data.
    #
    # @option params [required, String] :bucket
    #   The name of the bucket to which the multipart upload was initiated.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [Integer] :content_length
    #   Size of the body in bytes. This parameter is useful when the size of
    #   the body cannot be determined automatically.
    #
    # @option params [String] :content_md5
    #   The base64-encoded 128-bit MD5 digest of the part data. This parameter
    #   is auto-populated when using the command from the CLI. This parameter
    #   is required if object lock parameters are specified.
    #
    # @option params [String] :checksum_algorithm
    #   Indicates the algorithm used to create the checksum for the object
    #   when using the SDK. This header will not provide any additional
    #   functionality if not using the SDK. When sending this header, there
    #   must be a corresponding `x-amz-checksum` or `x-amz-trailer` header
    #   sent. Otherwise, Amazon S3 fails the request with the HTTP status code
    #   `400 Bad Request`. For more information, see [Checking object
    #   integrity][1] in the *Amazon S3 User Guide*.
    #
    #   If you provide an individual checksum, Amazon S3 ignores any provided
    #   `ChecksumAlgorithm` parameter.
    #
    #   This checksum algorithm must be the same for all parts and it match
    #   the checksum value supplied in the `CreateMultipartUpload` request.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32 checksum of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32C checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 160-bit SHA-1 digest of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 256-bit SHA-256 digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [required, String] :key
    #   Object key for which the multipart upload was initiated.
    #
    # @option params [required, Integer] :part_number
    #   Part number of part being uploaded. This is a positive integer between
    #   1 and 10,000.
    #
    # @option params [required, String] :upload_id
    #   Upload ID identifying the multipart upload whose part is being
    #   uploaded.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm header`. This must be
    #   the same encryption key specified in the initiate multipart upload
    #   request.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    #
    # @return [Types::UploadPartOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::UploadPartOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::UploadPartOutput#etag #etag} => String
    #   * {Types::UploadPartOutput#checksum_crc32 #checksum_crc32} => String
    #   * {Types::UploadPartOutput#checksum_crc32c #checksum_crc32c} => String
    #   * {Types::UploadPartOutput#checksum_sha1 #checksum_sha1} => String
    #   * {Types::UploadPartOutput#checksum_sha256 #checksum_sha256} => String
    #   * {Types::UploadPartOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::UploadPartOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::UploadPartOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::UploadPartOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::UploadPartOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To upload a part
    #
    #   # The following example uploads part 1 of a multipart upload. The example specifies a file name for the part data. The
    #   # Upload ID is same that is returned by the initiate multipart upload.
    #
    #   resp = client.upload_part({
    #     body: "fileToUpload", 
    #     bucket: "examplebucket", 
    #     key: "examplelargeobject", 
    #     part_number: 1, 
    #     upload_id: "xadcOB_7YPBOJuoFiQ9cz4P3Pe6FIZwO4f7wN93uHsNBEw97pl5eNwzExg0LAT2dUN91cOmrEQHDsP3WA60CEg--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     etag: "\"d8c2eafd90c266e19ab9dcacc479f8af\"", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.upload_part({
    #     body: source_file,
    #     bucket: "BucketName", # required
    #     content_length: 1,
    #     content_md5: "ContentMD5",
    #     checksum_algorithm: "CRC32", # accepts CRC32, CRC32C, SHA1, SHA256
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     key: "ObjectKey", # required
    #     part_number: 1, # required
    #     upload_id: "MultipartUploadId", # required
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.etag #=> String
    #   resp.checksum_crc32 #=> String
    #   resp.checksum_crc32c #=> String
    #   resp.checksum_sha1 #=> String
    #   resp.checksum_sha256 #=> String
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPart AWS API Documentation
    #
    # @overload upload_part(params = {})
    # @param [Hash] params ({})
    def upload_part(params = {}, options = {})
      req = build_request(:upload_part, params)
      req.send_request(options)
    end

    # Uploads a part by copying data from an existing object as data source.
    # You specify the data source by adding the request header
    # `x-amz-copy-source` in your request and a byte range by adding the
    # request header `x-amz-copy-source-range` in your request.
    #
    # For information about maximum and minimum part sizes and other
    # multipart upload specifications, see [Multipart upload limits][1] in
    # the *Amazon S3 User Guide*.
    #
    # <note markdown="1"> Instead of using an existing object as part data, you might use the
    # [UploadPart][2] action and provide data in your request.
    #
    #  </note>
    #
    # You must initiate a multipart upload before you can upload any part.
    # In response to your initiate request. Amazon S3 returns a unique
    # identifier, the upload ID, that you must include in your upload part
    # request.
    #
    # For more information about using the `UploadPartCopy` operation, see
    # the following:
    #
    # * For conceptual information about multipart uploads, see [Uploading
    #   Objects Using Multipart Upload][3] in the *Amazon S3 User Guide*.
    #
    # * For information about permissions required to use the multipart
    #   upload API, see [Multipart Upload and Permissions][4] in the *Amazon
    #   S3 User Guide*.
    #
    # * For information about copying objects using a single atomic action
    #   vs. a multipart upload, see [Operations on Objects][5] in the
    #   *Amazon S3 User Guide*.
    #
    # * For information about using server-side encryption with
    #   customer-provided encryption keys with the `UploadPartCopy`
    #   operation, see [CopyObject][6] and [UploadPart][2].
    #
    # Note the following additional considerations about the request headers
    # `x-amz-copy-source-if-match`, `x-amz-copy-source-if-none-match`,
    # `x-amz-copy-source-if-unmodified-since`, and
    # `x-amz-copy-source-if-modified-since`:
    #
    #
    #
    # * **Consideration 1** - If both of the `x-amz-copy-source-if-match`
    #   and `x-amz-copy-source-if-unmodified-since` headers are present in
    #   the request as follows:
    #
    #   `x-amz-copy-source-if-match` condition evaluates to `true`, and;
    #
    #   `x-amz-copy-source-if-unmodified-since` condition evaluates to
    #   `false`;
    #
    #   Amazon S3 returns `200 OK` and copies the data.
    #
    # * **Consideration 2** - If both of the
    #   `x-amz-copy-source-if-none-match` and
    #   `x-amz-copy-source-if-modified-since` headers are present in the
    #   request as follows:
    #
    #   `x-amz-copy-source-if-none-match` condition evaluates to `false`,
    #   and;
    #
    #   `x-amz-copy-source-if-modified-since` condition evaluates to `true`;
    #
    #   Amazon S3 returns `412 Precondition Failed` response code.
    #
    # Versioning
    #
    # : If your bucket has versioning enabled, you could have multiple
    #   versions of the same object. By default, `x-amz-copy-source`
    #   identifies the current version of the object to copy. If the current
    #   version is a delete marker and you don't specify a versionId in the
    #   `x-amz-copy-source`, Amazon S3 returns a 404 error, because the
    #   object does not exist. If you specify versionId in the
    #   `x-amz-copy-source` and the versionId is a delete marker, Amazon S3
    #   returns an HTTP 400 error, because you are not allowed to specify a
    #   delete marker as a version for the `x-amz-copy-source`.
    #
    #   You can optionally specify a specific version of the source object
    #   to copy by adding the `versionId` subresource as shown in the
    #   following example:
    #
    #   `x-amz-copy-source: /bucket/object?versionId=version id`
    #
    # Special errors
    # : * * *Code: NoSuchUpload*
    #
    #     * *Cause: The specified multipart upload does not exist. The
    #       upload ID might be invalid, or the multipart upload might have
    #       been aborted or completed.*
    #
    #     * *HTTP Status Code: 404 Not Found*
    #
    #   * * *Code: InvalidRequest*
    #
    #     * *Cause: The specified copy source is not supported as a
    #       byte-range copy source.*
    #
    #     * *HTTP Status Code: 400 Bad Request*
    #
    # The following operations are related to `UploadPartCopy`:
    #
    # * [CreateMultipartUpload][7]
    #
    # * [UploadPart][2]
    #
    # * [CompleteMultipartUpload][8]
    #
    # * [AbortMultipartUpload][9]
    #
    # * [ListParts][10]
    #
    # * [ListMultipartUploads][11]
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/dev/uploadobjusingmpu.html
    # [4]: https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html
    # [5]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectOperations.html
    # [6]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
    # [7]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    # [8]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    # [9]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    # [10]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html
    # [11]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListMultipartUploads.html
    #
    # @option params [required, String] :bucket
    #   The bucket name.
    #
    #   When using this action with an access point, you must direct requests
    #   to the access point hostname. The access point hostname takes the form
    #   *AccessPointName*-*AccountId*.s3-accesspoint.*Region*.amazonaws.com.
    #   When using this action with an access point through the Amazon Web
    #   Services SDKs, you provide the access point ARN in place of the bucket
    #   name. For more information about access point ARNs, see [Using access
    #   points][1] in the *Amazon S3 User Guide*.
    #
    #   When you use this action with Amazon S3 on Outposts, you must direct
    #   requests to the S3 on Outposts hostname. The S3 on Outposts hostname
    #   takes the form `
    #   AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com`.
    #   When you use this action with S3 on Outposts through the Amazon Web
    #   Services SDKs, you provide the Outposts access point ARN in place of
    #   the bucket name. For more information about S3 on Outposts ARNs, see
    #   [What is S3 on Outposts][2] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html
    #   [2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html
    #
    # @option params [required, String] :copy_source
    #   Specifies the source object for the copy operation. You specify the
    #   value in one of two formats, depending on whether you want to access
    #   the source object through an [access point][1]:
    #
    #   * For objects not accessed through an access point, specify the name
    #     of the source bucket and key of the source object, separated by a
    #     slash (/). For example, to copy the object `reports/january.pdf`
    #     from the bucket `awsexamplebucket`, use
    #     `awsexamplebucket/reports/january.pdf`. The value must be
    #     URL-encoded.
    #
    #   * For objects accessed through access points, specify the Amazon
    #     Resource Name (ARN) of the object as accessed through the access
    #     point, in the format
    #     `arn:aws:s3:<Region>:<account-id>:accesspoint/<access-point-name>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through access
    #     point `my-access-point` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3:us-west-2:123456789012:accesspoint/my-access-point/object/reports/january.pdf`.
    #     The value must be URL encoded.
    #
    #     <note markdown="1"> Amazon S3 supports copy operations using access points only when the
    #     source and destination buckets are in the same Amazon Web Services
    #     Region.
    #
    #      </note>
    #
    #     Alternatively, for objects accessed through Amazon S3 on Outposts,
    #     specify the ARN of the object as accessed in the format
    #     `arn:aws:s3-outposts:<Region>:<account-id>:outpost/<outpost-id>/object/<key>`.
    #     For example, to copy the object `reports/january.pdf` through
    #     outpost `my-outpost` owned by account `123456789012` in Region
    #     `us-west-2`, use the URL encoding of
    #     `arn:aws:s3-outposts:us-west-2:123456789012:outpost/my-outpost/object/reports/january.pdf`.
    #     The value must be URL-encoded.
    #
    #   To copy a specific version of an object, append
    #   `?versionId=<version-id>` to the value (for example,
    #   `awsexamplebucket/reports/january.pdf?versionId=QUpfdndhfd8438MNFDN93jdnJFkdmqnh893`).
    #   If you don't specify a version ID, Amazon S3 copies the latest
    #   version of the source object.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html
    #
    # @option params [String] :copy_source_if_match
    #   Copies the object if its entity tag (ETag) matches the specified tag.
    #
    # @option params [Time,DateTime,Date,Integer,String] :copy_source_if_modified_since
    #   Copies the object if it has been modified since the specified time.
    #
    # @option params [String] :copy_source_if_none_match
    #   Copies the object if its entity tag (ETag) is different than the
    #   specified ETag.
    #
    # @option params [Time,DateTime,Date,Integer,String] :copy_source_if_unmodified_since
    #   Copies the object if it hasn't been modified since the specified
    #   time.
    #
    # @option params [String] :copy_source_range
    #   The range of bytes to copy from the source object. The range value
    #   must use the form bytes=first-last, where the first and last are the
    #   zero-based byte offsets to copy. For example, bytes=0-9 indicates that
    #   you want to copy the first 10 bytes of the source. You can copy a
    #   range only if the source object is greater than 5 MB.
    #
    # @option params [required, String] :key
    #   Object key for which the multipart upload was initiated.
    #
    # @option params [required, Integer] :part_number
    #   Part number of part being copied. This is a positive integer between 1
    #   and 10,000.
    #
    # @option params [required, String] :upload_id
    #   Upload ID identifying the multipart upload whose part is being copied.
    #
    # @option params [String] :sse_customer_algorithm
    #   Specifies the algorithm to use to when encrypting the object (for
    #   example, AES256).
    #
    # @option params [String] :sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use in
    #   encrypting data. This value is used to store the object and then it is
    #   discarded; Amazon S3 does not store the encryption key. The key must
    #   be appropriate for use with the algorithm specified in the
    #   `x-amz-server-side-encryption-customer-algorithm` header. This must be
    #   the same encryption key specified in the initiate multipart upload
    #   request.
    #
    # @option params [String] :sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :copy_source_sse_customer_algorithm
    #   Specifies the algorithm to use when decrypting the source object (for
    #   example, AES256).
    #
    # @option params [String] :copy_source_sse_customer_key
    #   Specifies the customer-provided encryption key for Amazon S3 to use to
    #   decrypt the source object. The encryption key provided in this header
    #   must be one that was used when the source object was created.
    #
    # @option params [String] :copy_source_sse_customer_key_md5
    #   Specifies the 128-bit MD5 digest of the encryption key according to
    #   RFC 1321. Amazon S3 uses this header for a message integrity check to
    #   ensure that the encryption key was transmitted without error.
    #
    # @option params [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    #
    # @option params [String] :expected_bucket_owner
    #   The account ID of the expected destination bucket owner. If the
    #   destination bucket is owned by a different account, the request fails
    #   with the HTTP status code `403 Forbidden` (access denied).
    #
    # @option params [String] :expected_source_bucket_owner
    #   The account ID of the expected source bucket owner. If the source
    #   bucket is owned by a different account, the request fails with the
    #   HTTP status code `403 Forbidden` (access denied).
    #
    # @return [Types::UploadPartCopyOutput] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::UploadPartCopyOutput#copy_source_version_id #copy_source_version_id} => String
    #   * {Types::UploadPartCopyOutput#copy_part_result #copy_part_result} => Types::CopyPartResult
    #   * {Types::UploadPartCopyOutput#server_side_encryption #server_side_encryption} => String
    #   * {Types::UploadPartCopyOutput#sse_customer_algorithm #sse_customer_algorithm} => String
    #   * {Types::UploadPartCopyOutput#sse_customer_key_md5 #sse_customer_key_md5} => String
    #   * {Types::UploadPartCopyOutput#ssekms_key_id #ssekms_key_id} => String
    #   * {Types::UploadPartCopyOutput#bucket_key_enabled #bucket_key_enabled} => Boolean
    #   * {Types::UploadPartCopyOutput#request_charged #request_charged} => String
    #
    #
    # @example Example: To upload a part by copying byte range from an existing object as data source
    #
    #   # The following example uploads a part of a multipart upload by copying a specified byte range from an existing object as
    #   # data source.
    #
    #   resp = client.upload_part_copy({
    #     bucket: "examplebucket", 
    #     copy_source: "/bucketname/sourceobjectkey", 
    #     copy_source_range: "bytes=1-100000", 
    #     key: "examplelargeobject", 
    #     part_number: 2, 
    #     upload_id: "exampleuoh_10OhKhT7YukE9bjzTPRiuaCotmZM_pFngJFir9OZNrSr5cWa3cq3LZSUsfjI4FI7PkP91We7Nrw--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     copy_part_result: {
    #       etag: "\"65d16d19e65a7508a51f043180edcc36\"", 
    #       last_modified: Time.parse("2016-12-29T21:44:28.000Z"), 
    #     }, 
    #   }
    #
    # @example Example: To upload a part by copying data from an existing object as data source
    #
    #   # The following example uploads a part of a multipart upload by copying data from an existing object as data source.
    #
    #   resp = client.upload_part_copy({
    #     bucket: "examplebucket", 
    #     copy_source: "/bucketname/sourceobjectkey", 
    #     key: "examplelargeobject", 
    #     part_number: 1, 
    #     upload_id: "exampleuoh_10OhKhT7YukE9bjzTPRiuaCotmZM_pFngJFir9OZNrSr5cWa3cq3LZSUsfjI4FI7PkP91We7Nrw--", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     copy_part_result: {
    #       etag: "\"b0c6f0e7e054ab8fa2536a2677f8734d\"", 
    #       last_modified: Time.parse("2016-12-29T21:24:43.000Z"), 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.upload_part_copy({
    #     bucket: "BucketName", # required
    #     copy_source: "CopySource", # required
    #     copy_source_if_match: "CopySourceIfMatch",
    #     copy_source_if_modified_since: Time.now,
    #     copy_source_if_none_match: "CopySourceIfNoneMatch",
    #     copy_source_if_unmodified_since: Time.now,
    #     copy_source_range: "CopySourceRange",
    #     key: "ObjectKey", # required
    #     part_number: 1, # required
    #     upload_id: "MultipartUploadId", # required
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     copy_source_sse_customer_algorithm: "CopySourceSSECustomerAlgorithm",
    #     copy_source_sse_customer_key: "CopySourceSSECustomerKey",
    #     copy_source_sse_customer_key_md5: "CopySourceSSECustomerKeyMD5",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     expected_source_bucket_owner: "AccountId",
    #   })
    #
    # @example Response structure
    #
    #   resp.copy_source_version_id #=> String
    #   resp.copy_part_result.etag #=> String
    #   resp.copy_part_result.last_modified #=> Time
    #   resp.copy_part_result.checksum_crc32 #=> String
    #   resp.copy_part_result.checksum_crc32c #=> String
    #   resp.copy_part_result.checksum_sha1 #=> String
    #   resp.copy_part_result.checksum_sha256 #=> String
    #   resp.server_side_encryption #=> String, one of "AES256", "aws:kms", "aws:kms:dsse"
    #   resp.sse_customer_algorithm #=> String
    #   resp.sse_customer_key_md5 #=> String
    #   resp.ssekms_key_id #=> String
    #   resp.bucket_key_enabled #=> Boolean
    #   resp.request_charged #=> String, one of "requester"
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/UploadPartCopy AWS API Documentation
    #
    # @overload upload_part_copy(params = {})
    # @param [Hash] params ({})
    def upload_part_copy(params = {}, options = {})
      req = build_request(:upload_part_copy, params)
      req.send_request(options)
    end

    # Passes transformed objects to a `GetObject` operation when using
    # Object Lambda access points. For information about Object Lambda
    # access points, see [Transforming objects with Object Lambda access
    # points][1] in the *Amazon S3 User Guide*.
    #
    # This operation supports metadata that can be returned by
    # [GetObject][2], in addition to `RequestRoute`, `RequestToken`,
    # `StatusCode`, `ErrorCode`, and `ErrorMessage`. The `GetObject`
    # response metadata is supported so that the `WriteGetObjectResponse`
    # caller, typically an Lambda function, can provide the same metadata
    # when it internally invokes `GetObject`. When `WriteGetObjectResponse`
    # is called by a customer-owned Lambda function, the metadata returned
    # to the end user `GetObject` call might differ from what Amazon S3
    # would normally return.
    #
    # You can include any number of metadata headers. When including a
    # metadata header, it should be prefaced with `x-amz-meta`. For example,
    # `x-amz-meta-my-custom-header: MyCustomValue`. The primary use case for
    # this is to forward `GetObject` metadata.
    #
    # Amazon Web Services provides some prebuilt Lambda functions that you
    # can use with S3 Object Lambda to detect and redact personally
    # identifiable information (PII) and decompress S3 objects. These Lambda
    # functions are available in the Amazon Web Services Serverless
    # Application Repository, and can be selected through the Amazon Web
    # Services Management Console when you create your Object Lambda access
    # point.
    #
    # Example 1: PII Access Control - This Lambda function uses Amazon
    # Comprehend, a natural language processing (NLP) service using machine
    # learning to find insights and relationships in text. It automatically
    # detects personally identifiable information (PII) such as names,
    # addresses, dates, credit card numbers, and social security numbers
    # from documents in your Amazon S3 bucket.
    #
    # Example 2: PII Redaction - This Lambda function uses Amazon
    # Comprehend, a natural language processing (NLP) service using machine
    # learning to find insights and relationships in text. It automatically
    # redacts personally identifiable information (PII) such as names,
    # addresses, dates, credit card numbers, and social security numbers
    # from documents in your Amazon S3 bucket.
    #
    # Example 3: Decompression - The Lambda function
    # S3ObjectLambdaDecompression, is equipped to decompress objects stored
    # in S3 in one of six compressed file formats including bzip2, gzip,
    # snappy, zlib, zstandard and ZIP.
    #
    # For information on how to view and use these functions, see [Using
    # Amazon Web Services built Lambda functions][3] in the *Amazon S3 User
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects.html
    # [2]: https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html
    # [3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/olap-examples.html
    #
    # @option params [required, String] :request_route
    #   Route prefix to the HTTP URL generated.
    #
    # @option params [required, String] :request_token
    #   A single use encrypted token that maps `WriteGetObjectResponse` to the
    #   end user `GetObject` request.
    #
    # @option params [String, IO] :body
    #   The object data.
    #
    # @option params [Integer] :status_code
    #   The integer status code for an HTTP response of a corresponding
    #   `GetObject` request. The following is a list of status codes.
    #
    #   * `200 - OK`
    #
    #   * `206 - Partial Content`
    #
    #   * `304 - Not Modified`
    #
    #   * `400 - Bad Request`
    #
    #   * `401 - Unauthorized`
    #
    #   * `403 - Forbidden`
    #
    #   * `404 - Not Found`
    #
    #   * `405 - Method Not Allowed`
    #
    #   * `409 - Conflict`
    #
    #   * `411 - Length Required`
    #
    #   * `412 - Precondition Failed`
    #
    #   * `416 - Range Not Satisfiable`
    #
    #   * `500 - Internal Server Error`
    #
    #   * `503 - Service Unavailable`
    #
    # @option params [String] :error_code
    #   A string that uniquely identifies an error condition. Returned in the
    #   &lt;Code&gt; tag of the error XML response for a corresponding
    #   `GetObject` call. Cannot be used with a successful `StatusCode` header
    #   or when the transformed object is provided in the body. All error
    #   codes from S3 are sentence-cased. The regular expression (regex) value
    #   is `"^[A-Z][a-zA-Z]+$"`.
    #
    # @option params [String] :error_message
    #   Contains a generic description of the error condition. Returned in the
    #   &lt;Message&gt; tag of the error XML response for a corresponding
    #   `GetObject` call. Cannot be used with a successful `StatusCode` header
    #   or when the transformed object is provided in body.
    #
    # @option params [String] :accept_ranges
    #   Indicates that a range of bytes was specified.
    #
    # @option params [String] :cache_control
    #   Specifies caching behavior along the request/reply chain.
    #
    # @option params [String] :content_disposition
    #   Specifies presentational information for the object.
    #
    # @option params [String] :content_encoding
    #   Specifies what content encodings have been applied to the object and
    #   thus what decoding mechanisms must be applied to obtain the media-type
    #   referenced by the Content-Type header field.
    #
    # @option params [String] :content_language
    #   The language the content is in.
    #
    # @option params [Integer] :content_length
    #   The size of the content body in bytes.
    #
    # @option params [String] :content_range
    #   The portion of the object returned in the response.
    #
    # @option params [String] :content_type
    #   A standard MIME type describing the format of the object data.
    #
    # @option params [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the base64-encoded, 32-bit CRC32 checksum of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the base64-encoded, 32-bit CRC32C checksum of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the base64-encoded, 160-bit SHA-1 digest of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This
    #   specifies the base64-encoded, 256-bit SHA-256 digest of the object
    #   returned by the Object Lambda function. This may not match the
    #   checksum for the object stored in Amazon S3. Amazon S3 will perform
    #   validation of the checksum values only when the original `GetObject`
    #   request required checksum validation. For more information about
    #   checksums, see [Checking object integrity][1] in the *Amazon S3 User
    #   Guide*.
    #
    #   Only one checksum header can be specified at a time. If you supply
    #   multiple checksum headers, this request will fail.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    #
    # @option params [Boolean] :delete_marker
    #   Specifies whether an object stored in Amazon S3 is (`true`) or is not
    #   (`false`) a delete marker.
    #
    # @option params [String] :etag
    #   An opaque identifier assigned by a web server to a specific version of
    #   a resource found at a URL.
    #
    # @option params [Time,DateTime,Date,Integer,String] :expires
    #   The date and time at which the object is no longer cacheable.
    #
    # @option params [String] :expiration
    #   If the object expiration is configured (see PUT Bucket lifecycle), the
    #   response includes this header. It includes the `expiry-date` and
    #   `rule-id` key-value pairs that provide the object expiration
    #   information. The value of the `rule-id` is URL-encoded.
    #
    # @option params [Time,DateTime,Date,Integer,String] :last_modified
    #   The date and time that the object was last modified.
    #
    # @option params [Integer] :missing_meta
    #   Set to the number of metadata entries not returned in `x-amz-meta`
    #   headers. This can happen if you create metadata using an API like SOAP
    #   that supports more flexible metadata than the REST API. For example,
    #   using SOAP, you can create metadata whose values are not legal HTTP
    #   headers.
    #
    # @option params [Hash<String,String>] :metadata
    #   A map of metadata to store with the object in S3.
    #
    # @option params [String] :object_lock_mode
    #   Indicates whether an object stored in Amazon S3 has Object Lock
    #   enabled. For more information about S3 Object Lock, see [Object
    #   Lock][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
    #
    # @option params [String] :object_lock_legal_hold_status
    #   Indicates whether an object stored in Amazon S3 has an active legal
    #   hold.
    #
    # @option params [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
    #   The date and time when Object Lock is configured to expire.
    #
    # @option params [Integer] :parts_count
    #   The count of parts this object has.
    #
    # @option params [String] :replication_status
    #   Indicates if request involves bucket that is either a source or
    #   destination in a Replication rule. For more information about S3
    #   Replication, see [Replication][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html
    #
    # @option params [String] :request_charged
    #   If present, indicates that the requester was successfully charged for
    #   the request.
    #
    # @option params [String] :restore
    #   Provides information about object restoration operation and expiration
    #   time of the restored object copy.
    #
    # @option params [String] :server_side_encryption
    #   The server-side encryption algorithm used when storing requested
    #   object in Amazon S3 (for example, AES256, `aws:kms`).
    #
    # @option params [String] :sse_customer_algorithm
    #   Encryption algorithm used if server-side encryption with a
    #   customer-provided encryption key was specified for object stored in
    #   Amazon S3.
    #
    # @option params [String] :ssekms_key_id
    #   If present, specifies the ID of the Amazon Web Services Key Management
    #   Service (Amazon Web Services KMS) symmetric encryption customer
    #   managed key that was used for stored in Amazon S3 object.
    #
    # @option params [String] :sse_customer_key_md5
    #   128-bit MD5 digest of customer-provided encryption key used in Amazon
    #   S3 to encrypt data stored in S3. For more information, see [Protecting
    #   data using server-side encryption with customer-provided encryption
    #   keys (SSE-C)][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html
    #
    # @option params [String] :storage_class
    #   Provides storage class information of the object. Amazon S3 returns
    #   this header for all objects except for S3 Standard storage class
    #   objects.
    #
    #   For more information, see [Storage Classes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html
    #
    # @option params [Integer] :tag_count
    #   The number of tags, if any, on the object.
    #
    # @option params [String] :version_id
    #   An ID used to reference a specific version of the object.
    #
    # @option params [Boolean] :bucket_key_enabled
    #   Indicates whether the object stored in Amazon S3 uses an S3 bucket key
    #   for server-side encryption with Amazon Web Services KMS (SSE-KMS).
    #
    # @return [Struct] Returns an empty {Seahorse::Client::Response response}.
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.write_get_object_response({
    #     request_route: "RequestRoute", # required
    #     request_token: "RequestToken", # required
    #     body: source_file,
    #     status_code: 1,
    #     error_code: "ErrorCode",
    #     error_message: "ErrorMessage",
    #     accept_ranges: "AcceptRanges",
    #     cache_control: "CacheControl",
    #     content_disposition: "ContentDisposition",
    #     content_encoding: "ContentEncoding",
    #     content_language: "ContentLanguage",
    #     content_length: 1,
    #     content_range: "ContentRange",
    #     content_type: "ContentType",
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     delete_marker: false,
    #     etag: "ETag",
    #     expires: Time.now,
    #     expiration: "Expiration",
    #     last_modified: Time.now,
    #     missing_meta: 1,
    #     metadata: {
    #       "MetadataKey" => "MetadataValue",
    #     },
    #     object_lock_mode: "GOVERNANCE", # accepts GOVERNANCE, COMPLIANCE
    #     object_lock_legal_hold_status: "ON", # accepts ON, OFF
    #     object_lock_retain_until_date: Time.now,
    #     parts_count: 1,
    #     replication_status: "COMPLETE", # accepts COMPLETE, PENDING, FAILED, REPLICA
    #     request_charged: "requester", # accepts requester
    #     restore: "Restore",
    #     server_side_encryption: "AES256", # accepts AES256, aws:kms, aws:kms:dsse
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     ssekms_key_id: "SSEKMSKeyId",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #     storage_class: "STANDARD", # accepts STANDARD, REDUCED_REDUNDANCY, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, DEEP_ARCHIVE, OUTPOSTS, GLACIER_IR, SNOW
    #     tag_count: 1,
    #     version_id: "ObjectVersionId",
    #     bucket_key_enabled: false,
    #   })
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/s3-2006-03-01/WriteGetObjectResponse AWS API Documentation
    #
    # @overload write_get_object_response(params = {})
    # @param [Hash] params ({})
    def write_get_object_response(params = {}, options = {})
      req = build_request(:write_get_object_response, params)
      req.send_request(options)
    end

    # @!endgroup

    # @param params ({})
    # @api private
    def build_request(operation_name, params = {})
      handlers = @handlers.for(operation_name)
      context = Seahorse::Client::RequestContext.new(
        operation_name: operation_name,
        operation: config.api.operation(operation_name),
        client: self,
        params: params,
        config: config)
      context[:gem_name] = 'aws-sdk-s3'
      context[:gem_version] = '1.126.0'
      Seahorse::Client::Request.new(handlers, context)
    end

    # Polls an API operation until a resource enters a desired state.
    #
    # ## Basic Usage
    #
    # A waiter will call an API operation until:
    #
    # * It is successful
    # * It enters a terminal state
    # * It makes the maximum number of attempts
    #
    # In between attempts, the waiter will sleep.
    #
    #     # polls in a loop, sleeping between attempts
    #     client.wait_until(waiter_name, params)
    #
    # ## Configuration
    #
    # You can configure the maximum number of polling attempts, and the
    # delay (in seconds) between each polling attempt. You can pass
    # configuration as the final arguments hash.
    #
    #     # poll for ~25 seconds
    #     client.wait_until(waiter_name, params, {
    #       max_attempts: 5,
    #       delay: 5,
    #     })
    #
    # ## Callbacks
    #
    # You can be notified before each polling attempt and before each
    # delay. If you throw `:success` or `:failure` from these callbacks,
    # it will terminate the waiter.
    #
    #     started_at = Time.now
    #     client.wait_until(waiter_name, params, {
    #
    #       # disable max attempts
    #       max_attempts: nil,
    #
    #       # poll for 1 hour, instead of a number of attempts
    #       before_wait: -> (attempts, response) do
    #         throw :failure if Time.now - started_at > 3600
    #       end
    #     })
    #
    # ## Handling Errors
    #
    # When a waiter is unsuccessful, it will raise an error.
    # All of the failure errors extend from
    # {Aws::Waiters::Errors::WaiterFailed}.
    #
    #     begin
    #       client.wait_until(...)
    #     rescue Aws::Waiters::Errors::WaiterFailed
    #       # resource did not enter the desired state in time
    #     end
    #
    # ## Valid Waiters
    #
    # The following table lists the valid waiter names, the operations they call,
    # and the default `:delay` and `:max_attempts` values.
    #
    # | waiter_name       | params               | :delay   | :max_attempts |
    # | ----------------- | -------------------- | -------- | ------------- |
    # | bucket_exists     | {Client#head_bucket} | 5        | 20            |
    # | bucket_not_exists | {Client#head_bucket} | 5        | 20            |
    # | object_exists     | {Client#head_object} | 5        | 20            |
    # | object_not_exists | {Client#head_object} | 5        | 20            |
    #
    # @raise [Errors::FailureStateError] Raised when the waiter terminates
    #   because the waiter has entered a state that it will not transition
    #   out of, preventing success.
    #
    # @raise [Errors::TooManyAttemptsError] Raised when the configured
    #   maximum number of attempts have been made, and the waiter is not
    #   yet successful.
    #
    # @raise [Errors::UnexpectedError] Raised when an error is encounted
    #   while polling for a resource that is not expected.
    #
    # @raise [Errors::NoSuchWaiterError] Raised when you request to wait
    #   for an unknown state.
    #
    # @return [Boolean] Returns `true` if the waiter was successful.
    # @param [Symbol] waiter_name
    # @param [Hash] params ({})
    # @param [Hash] options ({})
    # @option options [Integer] :max_attempts
    # @option options [Integer] :delay
    # @option options [Proc] :before_attempt
    # @option options [Proc] :before_wait
    def wait_until(waiter_name, params = {}, options = {})
      w = waiter(waiter_name, options)
      yield(w.waiter) if block_given? # deprecated
      w.wait(params)
    end

    # @api private
    # @deprecated
    def waiter_names
      waiters.keys
    end

    private

    # @param [Symbol] waiter_name
    # @param [Hash] options ({})
    def waiter(waiter_name, options = {})
      waiter_class = waiters[waiter_name]
      if waiter_class
        waiter_class.new(options.merge(client: self))
      else
        raise Aws::Waiters::Errors::NoSuchWaiterError.new(waiter_name, waiters.keys)
      end
    end

    def waiters
      {
        bucket_exists: Waiters::BucketExists,
        bucket_not_exists: Waiters::BucketNotExists,
        object_exists: Waiters::ObjectExists,
        object_not_exists: Waiters::ObjectNotExists
      }
    end

    class << self

      # @api private
      attr_reader :identifier

      # @api private
      def errors_module
        Errors
      end

    end
  end
end
