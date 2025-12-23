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
require 'aws-sdk-core/plugins/request_compression.rb'
require 'aws-sdk-core/plugins/defaults_mode.rb'
require 'aws-sdk-core/plugins/recursion_detection.rb'
require 'aws-sdk-core/plugins/sign.rb'
require 'aws-sdk-core/plugins/protocols/query.rb'
require 'aws-sdk-sts/plugins/sts_regional_endpoints.rb'

Aws::Plugins::GlobalConfiguration.add_identifier(:sts)

module Aws::STS
  # An API client for STS.  To construct a client, you need to configure a `:region` and `:credentials`.
  #
  #     client = Aws::STS::Client.new(
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

    @identifier = :sts

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
    add_plugin(Aws::Plugins::RequestCompression)
    add_plugin(Aws::Plugins::DefaultsMode)
    add_plugin(Aws::Plugins::RecursionDetection)
    add_plugin(Aws::Plugins::Sign)
    add_plugin(Aws::Plugins::Protocols::Query)
    add_plugin(Aws::STS::Plugins::STSRegionalEndpoints)
    add_plugin(Aws::STS::Plugins::Endpoints)

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
    #   @option options [Boolean] :disable_request_compression (false)
    #     When set to 'true' the request body will not be compressed
    #     for supported operations.
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
    #   @option options [Boolean] :ignore_configured_endpoint_urls
    #     Setting to true disables use of endpoint URLs provided via environment
    #     variables and the shared configuration file.
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
    #   @option options [String] :profile ("default")
    #     Used when loading credentials from the shared credentials file
    #     at HOME/.aws/credentials.  When not specified, 'default' is used.
    #
    #   @option options [Integer] :request_min_compression_size_bytes (10240)
    #     The minimum size in bytes that triggers compression for request
    #     bodies. The value must be non-negative integer value between 0
    #     and 10485780 bytes inclusive.
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
    #   @option options [String] :sdk_ua_app_id
    #     A unique and opaque application ID that is appended to the
    #     User-Agent header as app/<sdk_ua_app_id>. It should have a
    #     maximum length of 50.
    #
    #   @option options [String] :secret_access_key
    #
    #   @option options [String] :session_token
    #
    #   @option options [String] :sts_regional_endpoints ("regional")
    #     Passing in 'regional' to enable regional endpoint for STS for all supported
    #     regions (except 'aws-global'). Using 'legacy' mode will force all legacy
    #     regions to resolve to the STS global endpoint.
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
    #   @option options [Aws::STS::EndpointProvider] :endpoint_provider
    #     The endpoint provider used to resolve endpoints. Any object that responds to `#resolve_endpoint(parameters)` where `parameters` is a Struct similar to `Aws::STS::EndpointParameters`
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

    # Returns a set of temporary security credentials that you can use to
    # access Amazon Web Services resources. These temporary credentials
    # consist of an access key ID, a secret access key, and a security
    # token. Typically, you use `AssumeRole` within your account or for
    # cross-account access. For a comparison of `AssumeRole` with other API
    # operations that produce temporary credentials, see [Requesting
    # Temporary Security Credentials][1] and [Comparing the Amazon Web
    # Services STS API operations][2] in the *IAM User Guide*.
    #
    # **Permissions**
    #
    # The temporary security credentials created by `AssumeRole` can be used
    # to make API calls to any Amazon Web Services service with the
    # following exception: You cannot call the Amazon Web Services STS
    # `GetFederationToken` or `GetSessionToken` API operations.
    #
    # (Optional) You can pass inline or managed [session policies][3] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed policy
    # Amazon Resource Names (ARNs) to use as managed session policies. The
    # plaintext that you use for both inline and managed session policies
    # can't exceed 2,048 characters. Passing policies to this operation
    # returns new temporary credentials. The resulting session's
    # permissions are the intersection of the role's identity-based policy
    # and the session policies. You can use the role's temporary
    # credentials in subsequent Amazon Web Services API calls to access
    # resources in the account that owns the role. You cannot use session
    # policies to grant more permissions than those allowed by the
    # identity-based policy of the role that is being assumed. For more
    # information, see [Session Policies][3] in the *IAM User Guide*.
    #
    # When you create a role, you create two policies: a role trust policy
    # that specifies *who* can assume the role, and a permissions policy
    # that specifies *what* can be done with the role. You specify the
    # trusted principal that is allowed to assume the role in the role trust
    # policy.
    #
    # To assume a role from a different account, your Amazon Web Services
    # account must be trusted by the role. The trust relationship is defined
    # in the role's trust policy when the role is created. That trust
    # policy states which accounts are allowed to delegate that access to
    # users in the account.
    #
    # A user who wants to access a role in a different account must also
    # have permissions that are delegated from the account administrator.
    # The administrator must attach a policy that allows the user to call
    # `AssumeRole` for the ARN of the role in the other account.
    #
    # To allow a user to assume a role in the same account, you can do
    # either of the following:
    #
    # * Attach a policy to the user that allows the user to call
    #   `AssumeRole` (as long as the role's trust policy trusts the
    #   account).
    #
    # * Add the user as a principal directly in the role's trust policy.
    #
    # You can do either because the role’s trust policy acts as an IAM
    # resource-based policy. When a resource-based policy grants access to a
    # principal in the same account, no additional identity-based policy is
    # required. For more information about trust policies and resource-based
    # policies, see [IAM Policies][4] in the *IAM User Guide*.
    #
    # **Tags**
    #
    # (Optional) You can pass tag key-value pairs to your session. These
    # tags are called session tags. For more information about session tags,
    # see [Passing Session Tags in STS][5] in the *IAM User Guide*.
    #
    # An administrator must grant you the permissions necessary to pass
    # session tags. The administrator can also create granular permissions
    # to allow you to pass only specific session tags. For more information,
    # see [Tutorial: Using Tags for Attribute-Based Access Control][6] in
    # the *IAM User Guide*.
    #
    # You can set the session tags as transitive. Transitive tags persist
    # during role chaining. For more information, see [Chaining Roles with
    # Session Tags][7] in the *IAM User Guide*.
    #
    # **Using MFA with AssumeRole**
    #
    # (Optional) You can include multi-factor authentication (MFA)
    # information when you call `AssumeRole`. This is useful for
    # cross-account scenarios to ensure that the user that assumes the role
    # has been authenticated with an Amazon Web Services MFA device. In that
    # scenario, the trust policy of the role being assumed includes a
    # condition that tests for MFA authentication. If the caller does not
    # include valid MFA information, the request to assume the role is
    # denied. The condition in a trust policy that tests for MFA
    # authentication might look like the following example.
    #
    # `"Condition": \{"Bool": \{"aws:MultiFactorAuthPresent": true\}\}`
    #
    # For more information, see [Configuring MFA-Protected API Access][8] in
    # the *IAM User Guide* guide.
    #
    # To use MFA with `AssumeRole`, you pass values for the `SerialNumber`
    # and `TokenCode` parameters. The `SerialNumber` value identifies the
    # user's hardware or virtual MFA device. The `TokenCode` is the
    # time-based one-time password (TOTP) that the MFA device produces.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/MFAProtectedAPI.html
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role to assume.
    #
    # @option params [required, String] :role_session_name
    #   An identifier for the assumed role session.
    #
    #   Use the role session name to uniquely identify a session when the same
    #   role is assumed by different principals or for different reasons. In
    #   cross-account scenarios, the role session name is visible to, and can
    #   be logged by the account that owns the role. The role session name is
    #   also used in the ARN of the assumed role principal. This means that
    #   subsequent cross-account API requests that use the temporary security
    #   credentials will expose the role session name to the external account
    #   in their CloudTrail logs.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and managed
    #   session policies can't exceed 2,048 characters. For more information
    #   about ARNs, see [Amazon Resource Names (ARNs) and Amazon Web Services
    #   Service Namespaces][1] in the Amazon Web Services General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent Amazon Web Services
    #   API calls to access resources in the account that owns the role. You
    #   cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][2] in the *IAM
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   Amazon Web Services API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. The value specified can
    #   range from 900 seconds (15 minutes) up to the maximum session duration
    #   set for the role. The maximum session duration setting can have a
    #   value from 1 hour to 12 hours. If you specify a value higher than this
    #   setting or the administrator setting (whichever is lower), the
    #   operation fails. For example, if you specify a session duration of 12
    #   hours, but your administrator set the maximum session duration to 6
    #   hours, your operation fails.
    #
    #   Role chaining limits your Amazon Web Services CLI or Amazon Web
    #   Services API role session to a maximum of one hour. When you use the
    #   `AssumeRole` API operation to assume a role, you can specify the
    #   duration of your role session with the `DurationSeconds` parameter.
    #   You can specify a parameter value of up to 43200 seconds (12 hours),
    #   depending on the maximum session duration setting for your role.
    #   However, if you assume a role using role chaining and provide a
    #   `DurationSeconds` parameter value greater than one hour, the operation
    #   fails. To learn how to view the maximum value for your role, see [View
    #   the Maximum Session Duration Setting for a Role][1] in the *IAM User
    #   Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the Amazon Web Services Management
    #   Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @option params [Array<Types::Tag>] :tags
    #   A list of session tags that you want to pass. Each session tag
    #   consists of a key name and an associated value. For more information
    #   about session tags, see [Tagging Amazon Web Services STS Sessions][1]
    #   in the *IAM User Guide*.
    #
    #   This parameter is optional. You can pass up to 50 session tags. The
    #   plaintext session tag keys can’t exceed 128 characters, and the values
    #   can’t exceed 256 characters. For these and additional limits, see [IAM
    #   and STS Character Limits][2] in the *IAM User Guide*.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #   You can pass a session tag with the same key as a tag that is already
    #   attached to the role. When you do, session tags override a role tag
    #   with the same key.
    #
    #   Tag key–value pairs are not case sensitive, but case is preserved.
    #   This means that you cannot have separate `Department` and `department`
    #   tag keys. Assume that the role has the `Department`=`Marketing` tag
    #   and you pass the `department`=`engineering` session tag. `Department`
    #   and `department` are not saved as separate tags, and the session tag
    #   passed in the request takes precedence over the role tag.
    #
    #   Additionally, if you used temporary credentials to perform this
    #   operation, the new session inherits any transitive session tags from
    #   the calling session. If you pass a session tag with the same key as an
    #   inherited tag, the operation fails. To view the inherited tags for a
    #   session, see the CloudTrail logs. For more information, see [Viewing
    #   Session Tags in CloudTrail][3] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #   [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_ctlogs
    #
    # @option params [Array<String>] :transitive_tag_keys
    #   A list of keys for session tags that you want to set as transitive. If
    #   you set a tag key as transitive, the corresponding key and value
    #   passes to subsequent sessions in a role chain. For more information,
    #   see [Chaining Roles with Session Tags][1] in the *IAM User Guide*.
    #
    #   This parameter is optional. When you set session tags as transitive,
    #   the session policy and session tags packed binary limit is not
    #   affected.
    #
    #   If you choose not to specify a transitive tag key, then no tags are
    #   passed from this session to any subsequent sessions.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining
    #
    # @option params [String] :external_id
    #   A unique identifier that might be required when you assume a role in
    #   another account. If the administrator of the account to which the role
    #   belongs provided you with an external ID, then provide that value in
    #   the `ExternalId` parameter. This value can be any string, such as a
    #   passphrase or account number. A cross-account role is usually set up
    #   to trust everyone in an account. Therefore, the administrator of the
    #   trusting account might send an external ID to the administrator of the
    #   trusted account. That way, only someone with the ID can assume the
    #   role, rather than everyone in the account. For more information about
    #   the external ID, see [How to Use an External ID When Granting Access
    #   to Your Amazon Web Services Resources to a Third Party][1] in the *IAM
    #   User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html
    #
    # @option params [String] :serial_number
    #   The identification number of the MFA device that is associated with
    #   the user who is making the `AssumeRole` call. Specify this value if
    #   the trust policy of the role being assumed includes a condition that
    #   requires MFA authentication. The value is either the serial number for
    #   a hardware device (such as `GAHT12345678`) or an Amazon Resource Name
    #   (ARN) for a virtual device (such as
    #   `arn:aws:iam::123456789012:mfa/user`).
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [String] :token_code
    #   The value provided by the MFA device, if the trust policy of the role
    #   being assumed requires MFA. (In other words, if the policy includes a
    #   condition that tests for MFA). If the role being assumed requires MFA
    #   and if the `TokenCode` value is missing or expired, the `AssumeRole`
    #   call returns an "access denied" error.
    #
    #   The format for this parameter, as described by its regex pattern, is a
    #   sequence of six numeric digits.
    #
    # @option params [String] :source_identity
    #   The source identity specified by the principal that is calling the
    #   `AssumeRole` operation.
    #
    #   You can require users to specify a source identity when they assume a
    #   role. You do this by using the `sts:SourceIdentity` condition key in a
    #   role trust policy. You can use source identity information in
    #   CloudTrail logs to determine who took actions with a role. You can use
    #   the `aws:SourceIdentity` condition key to further control access to
    #   Amazon Web Services resources based on the value of source identity.
    #   For more information about using source identity, see [Monitor and
    #   control actions taken with assumed roles][1] in the *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-. You cannot use a value that begins with the text
    #   `aws:`. This prefix is reserved for Amazon Web Services internal use.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html
    #
    # @option params [Array<Types::ProvidedContext>] :provided_contexts
    #   A list of previously acquired trusted context assertions in the format
    #   of a JSON array. The trusted context assertion is signed and encrypted
    #   by Amazon Web Services STS.
    #
    #   The following is an example of a `ProvidedContext` value that includes
    #   a single trusted context assertion and the ARN of the context provider
    #   from which the trusted context assertion was generated.
    #
    #   `[\{"ProviderArn":"arn:aws:iam::aws:contextProvider/identitycenter","ContextAssertion":"trusted-context-assertion"\}]`
    #
    # @return [Types::AssumeRoleResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleResponse#packed_policy_size #packed_policy_size} => Integer
    #   * {Types::AssumeRoleResponse#source_identity #source_identity} => String
    #
    #
    # @example Example: To assume a role
    #
    #   resp = client.assume_role({
    #     external_id: "123ABC", 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #     role_arn: "arn:aws:iam::123456789012:role/demo", 
    #     role_session_name: "testAssumeRoleSession", 
    #     tags: [
    #       {
    #         key: "Project", 
    #         value: "Unicorn", 
    #       }, 
    #       {
    #         key: "Team", 
    #         value: "Automation", 
    #       }, 
    #       {
    #         key: "Cost-Center", 
    #         value: "12345", 
    #       }, 
    #     ], 
    #     transitive_tag_keys: [
    #       "Project", 
    #       "Cost-Center", 
    #     ], 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     assumed_role_user: {
    #       arn: "arn:aws:sts::123456789012:assumed-role/demo/Bob", 
    #       assumed_role_id: "ARO123EXAMPLE123:Bob", 
    #     }, 
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-15T23:28:33.359Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==", 
    #     }, 
    #     packed_policy_size: 8, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role({
    #     role_arn: "arnType", # required
    #     role_session_name: "roleSessionNameType", # required
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "unrestrictedSessionPolicyDocumentType",
    #     duration_seconds: 1,
    #     tags: [
    #       {
    #         key: "tagKeyType", # required
    #         value: "tagValueType", # required
    #       },
    #     ],
    #     transitive_tag_keys: ["tagKeyType"],
    #     external_id: "externalIdType",
    #     serial_number: "serialNumberType",
    #     token_code: "tokenCodeType",
    #     source_identity: "sourceIdentityType",
    #     provided_contexts: [
    #       {
    #         provider_arn: "arnType",
    #         context_assertion: "contextAssertionType",
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #   resp.source_identity #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRole AWS API Documentation
    #
    # @overload assume_role(params = {})
    # @param [Hash] params ({})
    def assume_role(params = {}, options = {})
      req = build_request(:assume_role, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials for users who have
    # been authenticated via a SAML authentication response. This operation
    # provides a mechanism for tying an enterprise identity store or
    # directory to role-based Amazon Web Services access without
    # user-specific credentials or configuration. For a comparison of
    # `AssumeRoleWithSAML` with the other API operations that produce
    # temporary credentials, see [Requesting Temporary Security
    # Credentials][1] and [Comparing the Amazon Web Services STS API
    # operations][2] in the *IAM User Guide*.
    #
    # The temporary security credentials returned by this operation consist
    # of an access key ID, a secret access key, and a security token.
    # Applications can use these temporary security credentials to sign
    # calls to Amazon Web Services services.
    #
    # **Session Duration**
    #
    # By default, the temporary security credentials created by
    # `AssumeRoleWithSAML` last for one hour. However, you can use the
    # optional `DurationSeconds` parameter to specify the duration of your
    # session. Your role session lasts for the duration that you specify, or
    # until the time specified in the SAML authentication response's
    # `SessionNotOnOrAfter` value, whichever is shorter. You can provide a
    # `DurationSeconds` value from 900 seconds (15 minutes) up to the
    # maximum session duration setting for the role. This setting can have a
    # value from 1 hour to 12 hours. To learn how to view the maximum value
    # for your role, see [View the Maximum Session Duration Setting for a
    # Role][3] in the *IAM User Guide*. The maximum session duration limit
    # applies when you use the `AssumeRole*` API operations or the
    # `assume-role*` CLI commands. However the limit does not apply when you
    # use those operations to create a console URL. For more information,
    # see [Using IAM Roles][4] in the *IAM User Guide*.
    #
    # <note markdown="1"> [Role chaining][5] limits your CLI or Amazon Web Services API role
    # session to a maximum of one hour. When you use the `AssumeRole` API
    # operation to assume a role, you can specify the duration of your role
    # session with the `DurationSeconds` parameter. You can specify a
    # parameter value of up to 43200 seconds (12 hours), depending on the
    # maximum session duration setting for your role. However, if you assume
    # a role using role chaining and provide a `DurationSeconds` parameter
    # value greater than one hour, the operation fails.
    #
    #  </note>
    #
    # **Permissions**
    #
    # The temporary security credentials created by `AssumeRoleWithSAML` can
    # be used to make API calls to any Amazon Web Services service with the
    # following exception: you cannot call the STS `GetFederationToken` or
    # `GetSessionToken` API operations.
    #
    # (Optional) You can pass inline or managed [session policies][6] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed policy
    # Amazon Resource Names (ARNs) to use as managed session policies. The
    # plaintext that you use for both inline and managed session policies
    # can't exceed 2,048 characters. Passing policies to this operation
    # returns new temporary credentials. The resulting session's
    # permissions are the intersection of the role's identity-based policy
    # and the session policies. You can use the role's temporary
    # credentials in subsequent Amazon Web Services API calls to access
    # resources in the account that owns the role. You cannot use session
    # policies to grant more permissions than those allowed by the
    # identity-based policy of the role that is being assumed. For more
    # information, see [Session Policies][6] in the *IAM User Guide*.
    #
    # Calling `AssumeRoleWithSAML` does not require the use of Amazon Web
    # Services security credentials. The identity of the caller is validated
    # by using keys in the metadata document that is uploaded for the SAML
    # provider entity for your identity provider.
    #
    # Calling `AssumeRoleWithSAML` can result in an entry in your CloudTrail
    # logs. The entry includes the value in the `NameID` element of the SAML
    # assertion. We recommend that you use a `NameIDType` that is not
    # associated with any personally identifiable information (PII). For
    # example, you could instead use the persistent identifier
    # (`urn:oasis:names:tc:SAML:2.0:nameid-format:persistent`).
    #
    # **Tags**
    #
    # (Optional) You can configure your IdP to pass attributes into your
    # SAML assertion as session tags. Each session tag consists of a key
    # name and an associated value. For more information about session tags,
    # see [Passing Session Tags in STS][7] in the *IAM User Guide*.
    #
    # You can pass up to 50 session tags. The plaintext session tag keys
    # can’t exceed 128 characters and the values can’t exceed 256
    # characters. For these and additional limits, see [IAM and STS
    # Character Limits][8] in the *IAM User Guide*.
    #
    # <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    # policy, managed policy ARNs, and session tags into a packed binary
    # format that has a separate limit. Your request can fail for this limit
    # even if your plaintext meets the other requirements. The
    # `PackedPolicySize` response element indicates by percentage how close
    # the policies and tags for your request are to the upper size limit.
    #
    #  </note>
    #
    # You can pass a session tag with the same key as a tag that is attached
    # to the role. When you do, session tags override the role's tags with
    # the same key.
    #
    # An administrator must grant you the permissions necessary to pass
    # session tags. The administrator can also create granular permissions
    # to allow you to pass only specific session tags. For more information,
    # see [Tutorial: Using Tags for Attribute-Based Access Control][9] in
    # the *IAM User Guide*.
    #
    # You can set the session tags as transitive. Transitive tags persist
    # during role chaining. For more information, see [Chaining Roles with
    # Session Tags][10] in the *IAM User Guide*.
    #
    # **SAML Configuration**
    #
    # Before your application can call `AssumeRoleWithSAML`, you must
    # configure your SAML identity provider (IdP) to issue the claims
    # required by Amazon Web Services. Additionally, you must use Identity
    # and Access Management (IAM) to create a SAML provider entity in your
    # Amazon Web Services account that represents your identity provider.
    # You must also create an IAM role that specifies this SAML provider in
    # its trust policy.
    #
    # For more information, see the following resources:
    #
    # * [About SAML 2.0-based Federation][11] in the *IAM User Guide*.
    #
    # * [Creating SAML Identity Providers][12] in the *IAM User Guide*.
    #
    # * [Configuring a Relying Party and Claims][13] in the *IAM User
    #   Guide*.
    #
    # * [Creating a Role for SAML 2.0 Federation][14] in the *IAM User
    #   Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-role-chaining
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html
    # [10]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining
    # [11]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_saml.html
    # [12]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml.html
    # [13]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_saml_relying-party.html
    # [14]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_saml.html
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #
    # @option params [required, String] :principal_arn
    #   The Amazon Resource Name (ARN) of the SAML provider in IAM that
    #   describes the IdP.
    #
    # @option params [required, String] :saml_assertion
    #   The base64 encoded SAML authentication response provided by the IdP.
    #
    #   For more information, see [Configuring a Relying Party and Adding
    #   Claims][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and managed
    #   session policies can't exceed 2,048 characters. For more information
    #   about ARNs, see [Amazon Resource Names (ARNs) and Amazon Web Services
    #   Service Namespaces][1] in the Amazon Web Services General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent Amazon Web Services
    #   API calls to access resources in the account that owns the role. You
    #   cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][2] in the *IAM
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   Amazon Web Services API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. Your role session lasts
    #   for the duration that you specify for the `DurationSeconds` parameter,
    #   or until the time specified in the SAML authentication response's
    #   `SessionNotOnOrAfter` value, whichever is shorter. You can provide a
    #   `DurationSeconds` value from 900 seconds (15 minutes) up to the
    #   maximum session duration setting for the role. This setting can have a
    #   value from 1 hour to 12 hours. If you specify a value higher than this
    #   setting, the operation fails. For example, if you specify a session
    #   duration of 12 hours, but your administrator set the maximum session
    #   duration to 6 hours, your operation fails. To learn how to view the
    #   maximum value for your role, see [View the Maximum Session Duration
    #   Setting for a Role][1] in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the Amazon Web Services Management
    #   Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @return [Types::AssumeRoleWithSAMLResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleWithSAMLResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleWithSAMLResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleWithSAMLResponse#packed_policy_size #packed_policy_size} => Integer
    #   * {Types::AssumeRoleWithSAMLResponse#subject #subject} => String
    #   * {Types::AssumeRoleWithSAMLResponse#subject_type #subject_type} => String
    #   * {Types::AssumeRoleWithSAMLResponse#issuer #issuer} => String
    #   * {Types::AssumeRoleWithSAMLResponse#audience #audience} => String
    #   * {Types::AssumeRoleWithSAMLResponse#name_qualifier #name_qualifier} => String
    #   * {Types::AssumeRoleWithSAMLResponse#source_identity #source_identity} => String
    #
    #
    # @example Example: To assume a role using a SAML assertion
    #
    #   resp = client.assume_role_with_saml({
    #     duration_seconds: 3600, 
    #     principal_arn: "arn:aws:iam::123456789012:saml-provider/SAML-test", 
    #     role_arn: "arn:aws:iam::123456789012:role/TestSaml", 
    #     saml_assertion: "VERYLONGENCODEDASSERTIONEXAMPLExzYW1sOkF1ZGllbmNlPmJsYW5rPC9zYW1sOkF1ZGllbmNlPjwvc2FtbDpBdWRpZW5jZVJlc3RyaWN0aW9uPjwvc2FtbDpDb25kaXRpb25zPjxzYW1sOlN1YmplY3Q+PHNhbWw6TmFtZUlEIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOm5hbWVpZC1mb3JtYXQ6dHJhbnNpZW50Ij5TYW1sRXhhbXBsZTwvc2FtbDpOYW1lSUQ+PHNhbWw6U3ViamVjdENvbmZpcm1hdGlvbiBNZXRob2Q9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpjbTpiZWFyZXIiPjxzYW1sOlN1YmplY3RDb25maXJtYXRpb25EYXRhIE5vdE9uT3JBZnRlcj0iMjAxOS0xMS0wMVQyMDoyNTowNS4xNDVaIiBSZWNpcGllbnQ9Imh0dHBzOi8vc2lnbmluLmF3cy5hbWF6b24uY29tL3NhbWwiLz48L3NhbWw6U3ViamVjdENvbmZpcm1hdGlvbj48L3NhbWw6U3ViamVjdD48c2FtbDpBdXRoblN0YXRlbWVudCBBdXRoPD94bWwgdmpSZXNwb25zZT4=", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     assumed_role_user: {
    #       arn: "arn:aws:sts::123456789012:assumed-role/TestSaml", 
    #       assumed_role_id: "ARO456EXAMPLE789:TestSaml", 
    #     }, 
    #     audience: "https://signin.aws.amazon.com/saml", 
    #     credentials: {
    #       access_key_id: "ASIAV3ZUEFP6EXAMPLE", 
    #       expiration: Time.parse("2019-11-01T20:26:47Z"), 
    #       secret_access_key: "8P+SQvWIuLnKhh8d++jpw0nNmQRBZvNEXAMPLEKEY", 
    #       session_token: "IQoJb3JpZ2luX2VjEOz////////////////////wEXAMPLEtMSJHMEUCIDoKK3JH9uGQE1z0sINr5M4jk+Na8KHDcCYRVjJCZEvOAiEA3OvJGtw1EcViOleS2vhs8VdCKFJQWPQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==", 
    #     }, 
    #     issuer: "https://integ.example.com/idp/shibboleth", 
    #     name_qualifier: "SbdGOnUkh1i4+EXAMPLExL/jEvs=", 
    #     packed_policy_size: 6, 
    #     subject: "SamlExample", 
    #     subject_type: "transient", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role_with_saml({
    #     role_arn: "arnType", # required
    #     principal_arn: "arnType", # required
    #     saml_assertion: "SAMLAssertionType", # required
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "sessionPolicyDocumentType",
    #     duration_seconds: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #   resp.subject #=> String
    #   resp.subject_type #=> String
    #   resp.issuer #=> String
    #   resp.audience #=> String
    #   resp.name_qualifier #=> String
    #   resp.source_identity #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAML AWS API Documentation
    #
    # @overload assume_role_with_saml(params = {})
    # @param [Hash] params ({})
    def assume_role_with_saml(params = {}, options = {})
      req = build_request(:assume_role_with_saml, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials for users who have
    # been authenticated in a mobile or web application with a web identity
    # provider. Example providers include the OAuth 2.0 providers Login with
    # Amazon and Facebook, or any OpenID Connect-compatible identity
    # provider such as Google or [Amazon Cognito federated identities][1].
    #
    # <note markdown="1"> For mobile applications, we recommend that you use Amazon Cognito. You
    # can use Amazon Cognito with the [Amazon Web Services SDK for iOS
    # Developer Guide][2] and the [Amazon Web Services SDK for Android
    # Developer Guide][3] to uniquely identify a user. You can also supply
    # the user with a consistent identity throughout the lifetime of an
    # application.
    #
    #  To learn more about Amazon Cognito, see [Amazon Cognito identity
    # pools][1] in *Amazon Cognito Developer Guide*.
    #
    #  </note>
    #
    # Calling `AssumeRoleWithWebIdentity` does not require the use of Amazon
    # Web Services security credentials. Therefore, you can distribute an
    # application (for example, on mobile devices) that requests temporary
    # security credentials without including long-term Amazon Web Services
    # credentials in the application. You also don't need to deploy
    # server-based proxy services that use long-term Amazon Web Services
    # credentials. Instead, the identity of the caller is validated by using
    # a token from the web identity provider. For a comparison of
    # `AssumeRoleWithWebIdentity` with the other API operations that produce
    # temporary credentials, see [Requesting Temporary Security
    # Credentials][4] and [Comparing the Amazon Web Services STS API
    # operations][5] in the *IAM User Guide*.
    #
    # The temporary security credentials returned by this API consist of an
    # access key ID, a secret access key, and a security token. Applications
    # can use these temporary security credentials to sign calls to Amazon
    # Web Services service API operations.
    #
    # **Session Duration**
    #
    # By default, the temporary security credentials created by
    # `AssumeRoleWithWebIdentity` last for one hour. However, you can use
    # the optional `DurationSeconds` parameter to specify the duration of
    # your session. You can provide a value from 900 seconds (15 minutes) up
    # to the maximum session duration setting for the role. This setting can
    # have a value from 1 hour to 12 hours. To learn how to view the maximum
    # value for your role, see [View the Maximum Session Duration Setting
    # for a Role][6] in the *IAM User Guide*. The maximum session duration
    # limit applies when you use the `AssumeRole*` API operations or the
    # `assume-role*` CLI commands. However the limit does not apply when you
    # use those operations to create a console URL. For more information,
    # see [Using IAM Roles][7] in the *IAM User Guide*.
    #
    # **Permissions**
    #
    # The temporary security credentials created by
    # `AssumeRoleWithWebIdentity` can be used to make API calls to any
    # Amazon Web Services service with the following exception: you cannot
    # call the STS `GetFederationToken` or `GetSessionToken` API operations.
    #
    # (Optional) You can pass inline or managed [session policies][8] to
    # this operation. You can pass a single JSON policy document to use as
    # an inline session policy. You can also specify up to 10 managed policy
    # Amazon Resource Names (ARNs) to use as managed session policies. The
    # plaintext that you use for both inline and managed session policies
    # can't exceed 2,048 characters. Passing policies to this operation
    # returns new temporary credentials. The resulting session's
    # permissions are the intersection of the role's identity-based policy
    # and the session policies. You can use the role's temporary
    # credentials in subsequent Amazon Web Services API calls to access
    # resources in the account that owns the role. You cannot use session
    # policies to grant more permissions than those allowed by the
    # identity-based policy of the role that is being assumed. For more
    # information, see [Session Policies][8] in the *IAM User Guide*.
    #
    # **Tags**
    #
    # (Optional) You can configure your IdP to pass attributes into your web
    # identity token as session tags. Each session tag consists of a key
    # name and an associated value. For more information about session tags,
    # see [Passing Session Tags in STS][9] in the *IAM User Guide*.
    #
    # You can pass up to 50 session tags. The plaintext session tag keys
    # can’t exceed 128 characters and the values can’t exceed 256
    # characters. For these and additional limits, see [IAM and STS
    # Character Limits][10] in the *IAM User Guide*.
    #
    # <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    # policy, managed policy ARNs, and session tags into a packed binary
    # format that has a separate limit. Your request can fail for this limit
    # even if your plaintext meets the other requirements. The
    # `PackedPolicySize` response element indicates by percentage how close
    # the policies and tags for your request are to the upper size limit.
    #
    #  </note>
    #
    # You can pass a session tag with the same key as a tag that is attached
    # to the role. When you do, the session tag overrides the role tag with
    # the same key.
    #
    # An administrator must grant you the permissions necessary to pass
    # session tags. The administrator can also create granular permissions
    # to allow you to pass only specific session tags. For more information,
    # see [Tutorial: Using Tags for Attribute-Based Access Control][11] in
    # the *IAM User Guide*.
    #
    # You can set the session tags as transitive. Transitive tags persist
    # during role chaining. For more information, see [Chaining Roles with
    # Session Tags][12] in the *IAM User Guide*.
    #
    # **Identities**
    #
    # Before your application can call `AssumeRoleWithWebIdentity`, you must
    # have an identity token from a supported identity provider and create a
    # role that the application can assume. The role that your application
    # assumes must trust the identity provider that is associated with the
    # identity token. In other words, the identity provider must be
    # specified in the role's trust policy.
    #
    # Calling `AssumeRoleWithWebIdentity` can result in an entry in your
    # CloudTrail logs. The entry includes the [Subject][13] of the provided
    # web identity token. We recommend that you avoid using any personally
    # identifiable information (PII) in this field. For example, you could
    # instead use a GUID or a pairwise identifier, as [suggested in the OIDC
    # specification][14].
    #
    # For more information about how to use web identity federation and the
    # `AssumeRoleWithWebIdentity` API, see the following resources:
    #
    # * [Using Web Identity Federation API Operations for Mobile Apps][15]
    #   and [Federation Through a Web-based Identity Provider][16].
    #
    # * [ Web Identity Federation Playground][17]. Walk through the process
    #   of authenticating through Login with Amazon, Facebook, or Google,
    #   getting temporary security credentials, and then using those
    #   credentials to make a request to Amazon Web Services.
    #
    # * [Amazon Web Services SDK for iOS Developer Guide][2] and [Amazon Web
    #   Services SDK for Android Developer Guide][3]. These toolkits contain
    #   sample apps that show how to invoke the identity providers. The
    #   toolkits then show how to use the information from these providers
    #   to get and use temporary security credentials.
    #
    # * [Web Identity Federation with Mobile Applications][18]. This article
    #   discusses web identity federation and shows an example of how to use
    #   web identity federation to get access to content in Amazon S3.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-identity.html
    # [2]: http://aws.amazon.com/sdkforios/
    # [3]: http://aws.amazon.com/sdkforandroid/
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    # [10]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    # [11]: https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html
    # [12]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining
    # [13]: http://openid.net/specs/openid-connect-core-1_0.html#Claims
    # [14]: http://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes
    # [15]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc_manual.html
    # [16]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity
    # [17]: https://aws.amazon.com/blogs/aws/the-aws-web-identity-federation-playground/
    # [18]: http://aws.amazon.com/articles/web-identity-federation-with-mobile-applications
    #
    # @option params [required, String] :role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #
    # @option params [required, String] :role_session_name
    #   An identifier for the assumed role session. Typically, you pass the
    #   name or identifier that is associated with the user who is using your
    #   application. That way, the temporary security credentials that your
    #   application will use are associated with that user. This session name
    #   is included as part of the ARN and assumed role ID in the
    #   `AssumedRoleUser` response element.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [required, String] :web_identity_token
    #   The OAuth 2.0 access token or OpenID Connect ID token that is provided
    #   by the identity provider. Your application must get this token by
    #   authenticating the user who is using your application with a web
    #   identity provider before the application makes an
    #   `AssumeRoleWithWebIdentity` call. Only tokens with RSA algorithms
    #   (RS256) are supported.
    #
    # @option params [String] :provider_id
    #   The fully qualified host component of the domain name of the OAuth 2.0
    #   identity provider. Do not specify this value for an OpenID Connect
    #   identity provider.
    #
    #   Currently `www.amazon.com` and `graph.facebook.com` are the only
    #   supported identity providers for OAuth 2.0 access tokens. Do not
    #   include URL schemes and port numbers.
    #
    #   Do not specify this value for OpenID Connect ID tokens.
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as managed session policies. The policies must exist in
    #   the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and managed
    #   session policies can't exceed 2,048 characters. For more information
    #   about ARNs, see [Amazon Resource Names (ARNs) and Amazon Web Services
    #   Service Namespaces][1] in the Amazon Web Services General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary credentials.
    #   The resulting session's permissions are the intersection of the
    #   role's identity-based policy and the session policies. You can use
    #   the role's temporary credentials in subsequent Amazon Web Services
    #   API calls to access resources in the account that owns the role. You
    #   cannot use session policies to grant more permissions than those
    #   allowed by the identity-based policy of the role that is being
    #   assumed. For more information, see [Session Policies][2] in the *IAM
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   This parameter is optional. Passing policies to this operation returns
    #   new temporary credentials. The resulting session's permissions are
    #   the intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in subsequent
    #   Amazon Web Services API calls to access resources in the account that
    #   owns the role. You cannot use session policies to grant more
    #   permissions than those allowed by the identity-based policy of the
    #   role that is being assumed. For more information, see [Session
    #   Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to 12
    #   hours. If you specify a value higher than this setting, the operation
    #   fails. For example, if you specify a session duration of 12 hours, but
    #   your administrator set the maximum session duration to 6 hours, your
    #   operation fails. To learn how to view the maximum value for your role,
    #   see [View the Maximum Session Duration Setting for a Role][1] in the
    #   *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned credentials.
    #   The request to the federation endpoint for a console sign-in token
    #   takes a `SessionDuration` parameter that specifies the maximum length
    #   of the console session. For more information, see [Creating a URL that
    #   Enables Federated Users to Access the Amazon Web Services Management
    #   Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #
    # @return [Types::AssumeRoleWithWebIdentityResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::AssumeRoleWithWebIdentityResponse#credentials #credentials} => Types::Credentials
    #   * {Types::AssumeRoleWithWebIdentityResponse#subject_from_web_identity_token #subject_from_web_identity_token} => String
    #   * {Types::AssumeRoleWithWebIdentityResponse#assumed_role_user #assumed_role_user} => Types::AssumedRoleUser
    #   * {Types::AssumeRoleWithWebIdentityResponse#packed_policy_size #packed_policy_size} => Integer
    #   * {Types::AssumeRoleWithWebIdentityResponse#provider #provider} => String
    #   * {Types::AssumeRoleWithWebIdentityResponse#audience #audience} => String
    #   * {Types::AssumeRoleWithWebIdentityResponse#source_identity #source_identity} => String
    #
    #
    # @example Example: To assume a role as an OpenID Connect-federated user
    #
    #   resp = client.assume_role_with_web_identity({
    #     duration_seconds: 3600, 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #     provider_id: "www.amazon.com", 
    #     role_arn: "arn:aws:iam::123456789012:role/FederatedWebIdentityRole", 
    #     role_session_name: "app1", 
    #     web_identity_token: "Atza%7CIQEBLjAsAhRFiXuWpUXuRvQ9PZL3GMFcYevydwIUFAHZwXZXXXXXXXXJnrulxKDHwy87oGKPznh0D6bEQZTSCzyoCtL_8S07pLpr0zMbn6w1lfVZKNTBdDansFBmtGnIsIapjI6xKR02Yc_2bQ8LZbUXSGm6Ry6_BG7PrtLZtj_dfCTj92xNGed-CrKqjG7nPBjNIL016GGvuS5gSvPRUxWES3VYfm1wl7WTI7jn-Pcb6M-buCgHhFOzTQxod27L9CqnOLio7N3gZAGpsp6n1-AJBOCJckcyXe2c6uD0srOJeZlKUm2eTDVMf8IehDVI0r1QOnTV6KzzAI3OY87Vd_cVMQ", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     assumed_role_user: {
    #       arn: "arn:aws:sts::123456789012:assumed-role/FederatedWebIdentityRole/app1", 
    #       assumed_role_id: "AROACLKWSDQRAOEXAMPLE:app1", 
    #     }, 
    #     audience: "client.5498841531868486423.1548@apps.example.com", 
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2014-10-24T23:00:23Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEE0a8ANXXXXXXXXNO1ewxE5TijQyp+IEXAMPLE", 
    #     }, 
    #     packed_policy_size: 123, 
    #     provider: "www.amazon.com", 
    #     subject_from_web_identity_token: "amzn1.account.AF6RHO7KZU5XRVQJGXK6HEXAMPLE", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.assume_role_with_web_identity({
    #     role_arn: "arnType", # required
    #     role_session_name: "roleSessionNameType", # required
    #     web_identity_token: "clientTokenType", # required
    #     provider_id: "urlType",
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     policy: "sessionPolicyDocumentType",
    #     duration_seconds: 1,
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.subject_from_web_identity_token #=> String
    #   resp.assumed_role_user.assumed_role_id #=> String
    #   resp.assumed_role_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #   resp.provider #=> String
    #   resp.audience #=> String
    #   resp.source_identity #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentity AWS API Documentation
    #
    # @overload assume_role_with_web_identity(params = {})
    # @param [Hash] params ({})
    def assume_role_with_web_identity(params = {}, options = {})
      req = build_request(:assume_role_with_web_identity, params)
      req.send_request(options)
    end

    # Decodes additional information about the authorization status of a
    # request from an encoded message returned in response to an Amazon Web
    # Services request.
    #
    # For example, if a user is not authorized to perform an operation that
    # he or she has requested, the request returns a
    # `Client.UnauthorizedOperation` response (an HTTP 403 response). Some
    # Amazon Web Services operations additionally return an encoded message
    # that can provide details about this authorization failure.
    #
    # <note markdown="1"> Only certain Amazon Web Services operations return an encoded
    # authorization message. The documentation for an individual operation
    # indicates whether that operation returns an encoded message in
    # addition to returning an HTTP code.
    #
    #  </note>
    #
    # The message is encoded because the details of the authorization status
    # can contain privileged information that the user who requested the
    # operation should not see. To decode an authorization status message, a
    # user must be granted permissions through an IAM [policy][1] to request
    # the `DecodeAuthorizationMessage` (`sts:DecodeAuthorizationMessage`)
    # action.
    #
    # The decoded message includes the following type of information:
    #
    # * Whether the request was denied due to an explicit deny or due to the
    #   absence of an explicit allow. For more information, see [Determining
    #   Whether a Request is Allowed or Denied][2] in the *IAM User Guide*.
    #
    # * The principal who made the request.
    #
    # * The requested action.
    #
    # * The requested resource.
    #
    # * The values of condition keys in the context of the user's request.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow
    #
    # @option params [required, String] :encoded_message
    #   The encoded message that was returned with the response.
    #
    # @return [Types::DecodeAuthorizationMessageResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::DecodeAuthorizationMessageResponse#decoded_message #decoded_message} => String
    #
    #
    # @example Example: To decode information about an authorization status of a request
    #
    #   resp = client.decode_authorization_message({
    #     encoded_message: "<encoded-message>", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     decoded_message: "{\"allowed\": \"false\",\"explicitDeny\": \"false\",\"matchedStatements\": \"\",\"failures\": \"\",\"context\": {\"principal\": {\"id\": \"AIDACKCEVSQ6C2EXAMPLE\",\"name\": \"Bob\",\"arn\": \"arn:aws:iam::123456789012:user/Bob\"},\"action\": \"ec2:StopInstances\",\"resource\": \"arn:aws:ec2:us-east-1:123456789012:instance/i-dd01c9bd\",\"conditions\": [{\"item\": {\"key\": \"ec2:Tenancy\",\"values\": [\"default\"]},{\"item\": {\"key\": \"ec2:ResourceTag/elasticbeanstalk:environment-name\",\"values\": [\"Default-Environment\"]}},(Additional items ...)]}}", 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.decode_authorization_message({
    #     encoded_message: "encodedMessageType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.decoded_message #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessage AWS API Documentation
    #
    # @overload decode_authorization_message(params = {})
    # @param [Hash] params ({})
    def decode_authorization_message(params = {}, options = {})
      req = build_request(:decode_authorization_message, params)
      req.send_request(options)
    end

    # Returns the account identifier for the specified access key ID.
    #
    # Access keys consist of two parts: an access key ID (for example,
    # `AKIAIOSFODNN7EXAMPLE`) and a secret access key (for example,
    # `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`). For more information
    # about access keys, see [Managing Access Keys for IAM Users][1] in the
    # *IAM User Guide*.
    #
    # When you pass an access key ID to this operation, it returns the ID of
    # the Amazon Web Services account to which the keys belong. Access key
    # IDs beginning with `AKIA` are long-term credentials for an IAM user or
    # the Amazon Web Services account root user. Access key IDs beginning
    # with `ASIA` are temporary credentials that are created using STS
    # operations. If the account in the response belongs to you, you can
    # sign in as the root user and review your root user access keys. Then,
    # you can pull a [credentials report][2] to learn which IAM user owns
    # the keys. To learn who requested the temporary credentials for an
    # `ASIA` access key, view the STS events in your [CloudTrail logs][3] in
    # the *IAM User Guide*.
    #
    # This operation does not indicate the state of the access key. The key
    # might be active, inactive, or deleted. Active keys might not have
    # permissions to perform an operation. Providing a deleted access key
    # might return an error that the key doesn't exist.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html
    #
    # @option params [required, String] :access_key_id
    #   The identifier of an access key.
    #
    #   This parameter allows (through its regex pattern) a string of
    #   characters that can consist of any upper- or lowercase letter or
    #   digit.
    #
    # @return [Types::GetAccessKeyInfoResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetAccessKeyInfoResponse#account #account} => String
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_access_key_info({
    #     access_key_id: "accessKeyIdType", # required
    #   })
    #
    # @example Response structure
    #
    #   resp.account #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetAccessKeyInfo AWS API Documentation
    #
    # @overload get_access_key_info(params = {})
    # @param [Hash] params ({})
    def get_access_key_info(params = {}, options = {})
      req = build_request(:get_access_key_info, params)
      req.send_request(options)
    end

    # Returns details about the IAM user or role whose credentials are used
    # to call the operation.
    #
    # <note markdown="1"> No permissions are required to perform this operation. If an
    # administrator attaches a policy to your identity that explicitly
    # denies access to the `sts:GetCallerIdentity` action, you can still
    # perform this operation. Permissions are not required because the same
    # information is returned when access is denied. To view an example
    # response, see [I Am Not Authorized to Perform:
    # iam:DeleteVirtualMFADevice][1] in the *IAM User Guide*.
    #
    #  </note>
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_general.html#troubleshoot_general_access-denied-delete-mfa
    #
    # @return [Types::GetCallerIdentityResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetCallerIdentityResponse#user_id #user_id} => String
    #   * {Types::GetCallerIdentityResponse#account #account} => String
    #   * {Types::GetCallerIdentityResponse#arn #arn} => String
    #
    #
    # @example Example: To get details about a calling IAM user
    #
    #   # This example shows a request and response made with the credentials for a user named Alice in the AWS account
    #   # 123456789012.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:iam::123456789012:user/Alice", 
    #     user_id: "AKIAI44QH8DHBEXAMPLE", 
    #   }
    #
    # @example Example: To get details about a calling user federated with AssumeRole
    #
    #   # This example shows a request and response made with temporary credentials created by AssumeRole. The name of the assumed
    #   # role is my-role-name, and the RoleSessionName is set to my-role-session-name.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:sts::123456789012:assumed-role/my-role-name/my-role-session-name", 
    #     user_id: "AKIAI44QH8DHBEXAMPLE:my-role-session-name", 
    #   }
    #
    # @example Example: To get details about a calling user federated with GetFederationToken
    #
    #   # This example shows a request and response made with temporary credentials created by using GetFederationToken. The Name
    #   # parameter is set to my-federated-user-name.
    #
    #   resp = client.get_caller_identity({
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     account: "123456789012", 
    #     arn: "arn:aws:sts::123456789012:federated-user/my-federated-user-name", 
    #     user_id: "123456789012:my-federated-user-name", 
    #   }
    #
    # @example Response structure
    #
    #   resp.user_id #=> String
    #   resp.account #=> String
    #   resp.arn #=> String
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentity AWS API Documentation
    #
    # @overload get_caller_identity(params = {})
    # @param [Hash] params ({})
    def get_caller_identity(params = {}, options = {})
      req = build_request(:get_caller_identity, params)
      req.send_request(options)
    end

    # Returns a set of temporary security credentials (consisting of an
    # access key ID, a secret access key, and a security token) for a user.
    # A typical use is in a proxy application that gets temporary security
    # credentials on behalf of distributed applications inside a corporate
    # network.
    #
    # You must call the `GetFederationToken` operation using the long-term
    # security credentials of an IAM user. As a result, this call is
    # appropriate in contexts where those credentials can be safeguarded,
    # usually in a server-based application. For a comparison of
    # `GetFederationToken` with the other API operations that produce
    # temporary credentials, see [Requesting Temporary Security
    # Credentials][1] and [Comparing the Amazon Web Services STS API
    # operations][2] in the *IAM User Guide*.
    #
    # Although it is possible to call `GetFederationToken` using the
    # security credentials of an Amazon Web Services account root user
    # rather than an IAM user that you create for the purpose of a proxy
    # application, we do not recommend it. For more information, see
    # [Safeguard your root user credentials and don't use them for everyday
    # tasks][3] in the *IAM User Guide*.
    #
    # <note markdown="1"> You can create a mobile-based or browser-based app that can
    # authenticate users using a web identity provider like Login with
    # Amazon, Facebook, Google, or an OpenID Connect-compatible identity
    # provider. In this case, we recommend that you use [Amazon Cognito][4]
    # or `AssumeRoleWithWebIdentity`. For more information, see [Federation
    # Through a Web-based Identity Provider][5] in the *IAM User Guide*.
    #
    #  </note>
    #
    # **Session duration**
    #
    # The temporary credentials are valid for the specified duration, from
    # 900 seconds (15 minutes) up to a maximum of 129,600 seconds (36
    # hours). The default session duration is 43,200 seconds (12 hours).
    # Temporary credentials obtained by using the root user credentials have
    # a maximum duration of 3,600 seconds (1 hour).
    #
    # **Permissions**
    #
    # You can use the temporary credentials created by `GetFederationToken`
    # in any Amazon Web Services service with the following exceptions:
    #
    # * You cannot call any IAM operations using the CLI or the Amazon Web
    #   Services API. This limitation does not apply to console sessions.
    #
    # * You cannot call any STS operations except `GetCallerIdentity`.
    #
    # You can use temporary credentials for single sign-on (SSO) to the
    # console.
    #
    # You must pass an inline or managed [session policy][6] to this
    # operation. You can pass a single JSON policy document to use as an
    # inline session policy. You can also specify up to 10 managed policy
    # Amazon Resource Names (ARNs) to use as managed session policies. The
    # plaintext that you use for both inline and managed session policies
    # can't exceed 2,048 characters.
    #
    # Though the session policy parameters are optional, if you do not pass
    # a policy, then the resulting federated user session has no
    # permissions. When you pass session policies, the session permissions
    # are the intersection of the IAM user policies and the session policies
    # that you pass. This gives you a way to further restrict the
    # permissions for a federated user. You cannot use session policies to
    # grant more permissions than those that are defined in the permissions
    # policy of the IAM user. For more information, see [Session
    # Policies][6] in the *IAM User Guide*. For information about using
    # `GetFederationToken` to create temporary security credentials, see
    # [GetFederationToken—Federation Through a Custom Identity Broker][7].
    #
    # You can use the credentials to access a resource that has a
    # resource-based policy. If that policy specifically references the
    # federated user session in the `Principal` element of the policy, the
    # session has the permissions allowed by the policy. These permissions
    # are granted in addition to the permissions granted by the session
    # policies.
    #
    # **Tags**
    #
    # (Optional) You can pass tag key-value pairs to your session. These are
    # called session tags. For more information about session tags, see
    # [Passing Session Tags in STS][8] in the *IAM User Guide*.
    #
    # <note markdown="1"> You can create a mobile-based or browser-based app that can
    # authenticate users using a web identity provider like Login with
    # Amazon, Facebook, Google, or an OpenID Connect-compatible identity
    # provider. In this case, we recommend that you use [Amazon Cognito][4]
    # or `AssumeRoleWithWebIdentity`. For more information, see [Federation
    # Through a Web-based Identity Provider][5] in the *IAM User Guide*.
    #
    #  </note>
    #
    # An administrator must grant you the permissions necessary to pass
    # session tags. The administrator can also create granular permissions
    # to allow you to pass only specific session tags. For more information,
    # see [Tutorial: Using Tags for Attribute-Based Access Control][9] in
    # the *IAM User Guide*.
    #
    # Tag key–value pairs are not case sensitive, but case is preserved.
    # This means that you cannot have separate `Department` and `department`
    # tag keys. Assume that the user that you are federating has the
    # `Department`=`Marketing` tag and you pass the
    # `department`=`engineering` session tag. `Department` and `department`
    # are not saved as separate tags, and the session tag passed in the
    # request takes precedence over the user tag.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#lock-away-credentials
    # [4]: http://aws.amazon.com/cognito/
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_assumerolewithwebidentity
    # [6]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    # [7]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getfederationtoken
    # [8]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    # [9]: https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_attribute-based-access-control.html
    #
    # @option params [required, String] :name
    #   The name of the federated user. The name is used as an identifier for
    #   the temporary security credentials (such as `Bob`). For example, you
    #   can reference the federated user name in a resource-based policy, such
    #   as in an Amazon S3 bucket policy.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    # @option params [String] :policy
    #   An IAM policy in JSON format that you want to use as an inline session
    #   policy.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policy
    #   Amazon Resource Names (ARNs) to use as managed session policies.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions for
    #   a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][1] in the
    #   *IAM User Guide*.
    #
    #   The resulting credentials can be used to access a resource that has a
    #   resource-based policy. If that policy specifically references the
    #   federated user session in the `Principal` element of the policy, the
    #   session has the permissions allowed by the policy. These permissions
    #   are granted in addition to the permissions that are granted by the
    #   session policies.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of the
    #   valid character list (\\u0020 through \\u00FF). It can also include
    #   the tab (\\u0009), linefeed (\\u000A), and carriage return (\\u000D)
    #   characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #
    # @option params [Array<Types::PolicyDescriptorType>] :policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that you
    #   want to use as a managed session policy. The policies must exist in
    #   the same account as the IAM user that is requesting federated access.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policy
    #   Amazon Resource Names (ARNs) to use as managed session policies. The
    #   plaintext that you use for both inline and managed session policies
    #   can't exceed 2,048 characters. You can provide up to 10 managed
    #   policy ARNs. For more information about ARNs, see [Amazon Resource
    #   Names (ARNs) and Amazon Web Services Service Namespaces][2] in the
    #   Amazon Web Services General Reference.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions for
    #   a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][1] in the
    #   *IAM User Guide*.
    #
    #   The resulting credentials can be used to access a resource that has a
    #   resource-based policy. If that policy specifically references the
    #   federated user session in the `Principal` element of the policy, the
    #   session has the permissions allowed by the policy. These permissions
    #   are granted in addition to the permissions that are granted by the
    #   session policies.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, that the session should last. Acceptable
    #   durations for federation sessions range from 900 seconds (15 minutes)
    #   to 129,600 seconds (36 hours), with 43,200 seconds (12 hours) as the
    #   default. Sessions obtained using root user credentials are restricted
    #   to a maximum of 3,600 seconds (one hour). If the specified duration is
    #   longer than one hour, the session obtained by using root user
    #   credentials defaults to one hour.
    #
    # @option params [Array<Types::Tag>] :tags
    #   A list of session tags. Each session tag consists of a key name and an
    #   associated value. For more information about session tags, see
    #   [Passing Session Tags in STS][1] in the *IAM User Guide*.
    #
    #   This parameter is optional. You can pass up to 50 session tags. The
    #   plaintext session tag keys can’t exceed 128 characters and the values
    #   can’t exceed 256 characters. For these and additional limits, see [IAM
    #   and STS Character Limits][2] in the *IAM User Guide*.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline session
    #   policy, managed policy ARNs, and session tags into a packed binary
    #   format that has a separate limit. Your request can fail for this limit
    #   even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how close
    #   the policies and tags for your request are to the upper size limit.
    #
    #    </note>
    #
    #   You can pass a session tag with the same key as a tag that is already
    #   attached to the user you are federating. When you do, session tags
    #   override a user tag with the same key.
    #
    #   Tag key–value pairs are not case sensitive, but case is preserved.
    #   This means that you cannot have separate `Department` and `department`
    #   tag keys. Assume that the role has the `Department`=`Marketing` tag
    #   and you pass the `department`=`engineering` session tag. `Department`
    #   and `department` are not saved as separate tags, and the session tag
    #   passed in the request takes precedence over the role tag.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #
    # @return [Types::GetFederationTokenResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetFederationTokenResponse#credentials #credentials} => Types::Credentials
    #   * {Types::GetFederationTokenResponse#federated_user #federated_user} => Types::FederatedUser
    #   * {Types::GetFederationTokenResponse#packed_policy_size #packed_policy_size} => Integer
    #
    #
    # @example Example: To get temporary credentials for a role by using GetFederationToken
    #
    #   resp = client.get_federation_token({
    #     duration_seconds: 3600, 
    #     name: "testFedUserSession", 
    #     policy: "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"Stmt1\",\"Effect\":\"Allow\",\"Action\":\"s3:ListAllMyBuckets\",\"Resource\":\"*\"}]}", 
    #     tags: [
    #       {
    #         key: "Project", 
    #         value: "Pegasus", 
    #       }, 
    #       {
    #         key: "Cost-Center", 
    #         value: "98765", 
    #       }, 
    #     ], 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-15T23:28:33.359Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoDYXdzEPT//////////wEXAMPLEtc764bNrC9SAPBSM22wDOk4x4HIZ8j4FZTwdQWLWsKWHGBuFqwAeMicRXmxfpSPfIeoIYRqTflfKD8YUuwthAx7mSEI/qkPpKPi/kMcGdQrmGdeehM4IC1NtBmUpp2wUE8phUZampKsburEDy0KPkyQDYwT7WZ0wq5VSXDvp75YU9HFvlRd8Tx6q6fE8YQcHNVXAkiY9q6d+xo0rKwT38xVqr7ZD0u0iPPkUL64lIZbqBAz+scqKmlzm8FDrypNC9Yjc8fPOLn9FX9KSYvKTr4rvx3iSIlTJabIQwj2ICCR/oLxBA==", 
    #     }, 
    #     federated_user: {
    #       arn: "arn:aws:sts::123456789012:federated-user/Bob", 
    #       federated_user_id: "123456789012:Bob", 
    #     }, 
    #     packed_policy_size: 8, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_federation_token({
    #     name: "userNameType", # required
    #     policy: "sessionPolicyDocumentType",
    #     policy_arns: [
    #       {
    #         arn: "arnType",
    #       },
    #     ],
    #     duration_seconds: 1,
    #     tags: [
    #       {
    #         key: "tagKeyType", # required
    #         value: "tagValueType", # required
    #       },
    #     ],
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #   resp.federated_user.federated_user_id #=> String
    #   resp.federated_user.arn #=> String
    #   resp.packed_policy_size #=> Integer
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationToken AWS API Documentation
    #
    # @overload get_federation_token(params = {})
    # @param [Hash] params ({})
    def get_federation_token(params = {}, options = {})
      req = build_request(:get_federation_token, params)
      req.send_request(options)
    end

    # Returns a set of temporary credentials for an Amazon Web Services
    # account or IAM user. The credentials consist of an access key ID, a
    # secret access key, and a security token. Typically, you use
    # `GetSessionToken` if you want to use MFA to protect programmatic calls
    # to specific Amazon Web Services API operations like Amazon EC2
    # `StopInstances`.
    #
    # MFA-enabled IAM users must call `GetSessionToken` and submit an MFA
    # code that is associated with their MFA device. Using the temporary
    # security credentials that the call returns, IAM users can then make
    # programmatic calls to API operations that require MFA authentication.
    # An incorrect MFA code causes the API to return an access denied error.
    # For a comparison of `GetSessionToken` with the other API operations
    # that produce temporary credentials, see [Requesting Temporary Security
    # Credentials][1] and [Comparing the Amazon Web Services STS API
    # operations][2] in the *IAM User Guide*.
    #
    # <note markdown="1"> No permissions are required for users to perform this operation. The
    # purpose of the `sts:GetSessionToken` operation is to authenticate the
    # user using MFA. You cannot use policies to control authentication
    # operations. For more information, see [Permissions for
    # GetSessionToken][3] in the *IAM User Guide*.
    #
    #  </note>
    #
    # **Session Duration**
    #
    # The `GetSessionToken` operation must be called by using the long-term
    # Amazon Web Services security credentials of an IAM user. Credentials
    # that are created by IAM users are valid for the duration that you
    # specify. This duration can range from 900 seconds (15 minutes) up to a
    # maximum of 129,600 seconds (36 hours), with a default of 43,200
    # seconds (12 hours). Credentials based on account credentials can range
    # from 900 seconds (15 minutes) up to 3,600 seconds (1 hour), with a
    # default of 1 hour.
    #
    # **Permissions**
    #
    # The temporary security credentials created by `GetSessionToken` can be
    # used to make API calls to any Amazon Web Services service with the
    # following exceptions:
    #
    # * You cannot call any IAM API operations unless MFA authentication
    #   information is included in the request.
    #
    # * You cannot call any STS API *except* `AssumeRole` or
    #   `GetCallerIdentity`.
    #
    # The credentials that `GetSessionToken` returns are based on
    # permissions associated with the IAM user whose credentials were used
    # to call the operation. The temporary credentials have the same
    # permissions as the IAM user.
    #
    # <note markdown="1"> Although it is possible to call `GetSessionToken` using the security
    # credentials of an Amazon Web Services account root user rather than an
    # IAM user, we do not recommend it. If `GetSessionToken` is called using
    # root user credentials, the temporary credentials have root user
    # permissions. For more information, see [Safeguard your root user
    # credentials and don't use them for everyday tasks][4] in the *IAM
    # User Guide*
    #
    #  </note>
    #
    # For more information about using `GetSessionToken` to create temporary
    # credentials, see [Temporary Credentials for Users in Untrusted
    # Environments][5] in the *IAM User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison
    # [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_getsessiontoken.html
    # [4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#lock-away-credentials
    # [5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#api_getsessiontoken
    #
    # @option params [Integer] :duration_seconds
    #   The duration, in seconds, that the credentials should remain valid.
    #   Acceptable durations for IAM user sessions range from 900 seconds (15
    #   minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12 hours)
    #   as the default. Sessions for Amazon Web Services account owners are
    #   restricted to a maximum of 3,600 seconds (one hour). If the duration
    #   is longer than one hour, the session for Amazon Web Services account
    #   owners defaults to one hour.
    #
    # @option params [String] :serial_number
    #   The identification number of the MFA device that is associated with
    #   the IAM user who is making the `GetSessionToken` call. Specify this
    #   value if the IAM user has a policy that requires MFA authentication.
    #   The value is either the serial number for a hardware device (such as
    #   `GAHT12345678`) or an Amazon Resource Name (ARN) for a virtual device
    #   (such as `arn:aws:iam::123456789012:mfa/user`). You can find the
    #   device for an IAM user by going to the Amazon Web Services Management
    #   Console and viewing the user's security credentials.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    # @option params [String] :token_code
    #   The value provided by the MFA device, if MFA is required. If any
    #   policy requires the IAM user to submit an MFA code, specify this
    #   value. If MFA authentication is required, the user must provide a code
    #   when requesting a set of temporary security credentials. A user who
    #   fails to provide the code receives an "access denied" response when
    #   requesting resources that require MFA authentication.
    #
    #   The format for this parameter, as described by its regex pattern, is a
    #   sequence of six numeric digits.
    #
    # @return [Types::GetSessionTokenResponse] Returns a {Seahorse::Client::Response response} object which responds to the following methods:
    #
    #   * {Types::GetSessionTokenResponse#credentials #credentials} => Types::Credentials
    #
    #
    # @example Example: To get temporary credentials for an IAM user or an AWS account
    #
    #   resp = client.get_session_token({
    #     duration_seconds: 3600, 
    #     serial_number: "YourMFASerialNumber", 
    #     token_code: "123456", 
    #   })
    #
    #   resp.to_h outputs the following:
    #   {
    #     credentials: {
    #       access_key_id: "AKIAIOSFODNN7EXAMPLE", 
    #       expiration: Time.parse("2011-07-11T19:55:29.611Z"), 
    #       secret_access_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY", 
    #       session_token: "AQoEXAMPLEH4aoAH0gNCAPyJxz4BlCFFxWNE1OPTgk5TthT+FvwqnKwRcOIfrRh3c/LTo6UDdyJwOOvEVPvLXCrrrUtdnniCEXAMPLE/IvU1dYUg2RVAJBanLiHb4IgRmpRV3zrkuWJOgQs8IZZaIv2BXIa2R4OlgkBN9bkUDNCJiBeb/AXlzBBko7b15fjrBs2+cTQtpZ3CYWFXG8C5zqx37wnOE49mRl/+OtkIKGO7fAE", 
    #     }, 
    #   }
    #
    # @example Request syntax with placeholder values
    #
    #   resp = client.get_session_token({
    #     duration_seconds: 1,
    #     serial_number: "serialNumberType",
    #     token_code: "tokenCodeType",
    #   })
    #
    # @example Response structure
    #
    #   resp.credentials.access_key_id #=> String
    #   resp.credentials.secret_access_key #=> String
    #   resp.credentials.session_token #=> String
    #   resp.credentials.expiration #=> Time
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionToken AWS API Documentation
    #
    # @overload get_session_token(params = {})
    # @param [Hash] params ({})
    def get_session_token(params = {}, options = {})
      req = build_request(:get_session_token, params)
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
      context[:gem_name] = 'aws-sdk-core'
      context[:gem_version] = '3.188.0'
      Seahorse::Client::Request.new(handlers, context)
    end

    # @api private
    # @deprecated
    def waiter_names
      []
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
