# frozen_string_literal: true

require_relative 'defaults_mode_config_resolver'

module Aws

  # A defaults mode determines how certain default configuration options are resolved in the SDK.
  #
  # *Note*: For any mode other than `'legacy'` the vended default values might change as best practices may
  # evolve. As a result, it is encouraged to perform testing when upgrading the SDK if you are using a mode other than
  # `'legacy'`.  While the `'legacy'` defaults mode is specific to Ruby,
  # other modes are standardized across all of the AWS SDKs.
  #
  #  The defaults mode can be configured:
  #
  #  * Directly on a client via `:defaults_mode`
  #
  #  * On a configuration profile via the "defaults_mode" profile file property.
  #
  #  * Globally via the "AWS_DEFAULTS_MODE" environment variable.
  #
  #
  # #defaults START - documentation
  # The following `:default_mode` values are supported:
  #
  # * `'standard'` -
  #   The STANDARD mode provides the latest recommended default values
  #   that should be safe to run in most scenarios
  #
  #   Note that the default values vended from this mode might change as
  #   best practices may evolve. As a result, it is encouraged to perform
  #   tests when upgrading the SDK
  #
  # * `'in-region'` -
  #   The IN\_REGION mode builds on the standard mode and includes
  #   optimization tailored for applications which call AWS services from
  #   within the same AWS region
  #
  #   Note that the default values vended from this mode might change as
  #   best practices may evolve. As a result, it is encouraged to perform
  #   tests when upgrading the SDK
  #
  # * `'cross-region'` -
  #   The CROSS\_REGION mode builds on the standard mode and includes
  #   optimization tailored for applications which call AWS services in a
  #   different region
  #
  #   Note that the default values vended from this mode might change as
  #   best practices may evolve. As a result, it is encouraged to perform
  #   tests when upgrading the SDK
  #
  # * `'mobile'` -
  #   The MOBILE mode builds on the standard mode and includes
  #   optimization tailored for mobile applications
  #
  #   Note that the default values vended from this mode might change as
  #   best practices may evolve. As a result, it is encouraged to perform
  #   tests when upgrading the SDK
  #
  # * `'auto'` -
  #   The AUTO mode is an experimental mode that builds on the standard
  #   mode. The SDK will attempt to discover the execution environment to
  #   determine the appropriate settings automatically.
  #
  #   Note that the auto detection is heuristics-based and does not
  #   guarantee 100% accuracy. STANDARD mode will be used if the execution
  #   environment cannot be determined. The auto detection might query
  #   [EC2 Instance Metadata service][1], which might introduce latency.
  #   Therefore we recommend choosing an explicit defaults\_mode instead
  #   if startup latency is critical to your application
  #
  # * `'legacy'` -
  #   The LEGACY mode provides default settings that vary per SDK and were
  #   used prior to establishment of defaults\_mode
  #
  # Based on the provided mode, the SDK will vend sensible default values
  # tailored to the mode for the following settings:
  #
  # * `:retry_mode` -
  #   A retry mode specifies how the SDK attempts retries. See [Retry
  #   Mode][2]
  #
  # * `:sts_regional_endpoints` -
  #   Specifies how the SDK determines the AWS service endpoint that it
  #   uses to talk to the AWS Security Token Service (AWS STS). See
  #   [Setting STS Regional endpoints][3]
  #
  # * `:s3_us_east_1_regional_endpoint` -
  #   Specifies how the SDK determines the AWS service endpoint that it
  #   uses to talk to the Amazon S3 for the us-east-1 region
  #
  # * `:http_open_timeout` -
  #   The amount of time after making an initial connection attempt on a
  #   socket, where if the client does not receive a completion of the
  #   connect handshake, the client gives up and fails the operation
  #
  # * `:ssl_timeout` -
  #   The maximum amount of time that a TLS handshake is allowed to take
  #   from the time the CLIENT HELLO message is sent to ethe time the
  #   client and server have fully negotiated ciphers and exchanged keys
  #
  #  All options above can be configured by users, and the overridden value will take precedence.
  #
  # [1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
  # [2]: https://docs.aws.amazon.com/sdkref/latest/guide/setting-global-retry_mode.html
  # [3]: https://docs.aws.amazon.com/sdkref/latest/guide/setting-global-sts_regional_endpoints.html
  #
  # #defaults END - documentation
  module DefaultsModeConfiguration
    # @api private
    # #defaults START - configuration
    SDK_DEFAULT_CONFIGURATION = 
    {
      "version" => 1,
      "base" => {
        "retryMode" => "standard",
        "stsRegionalEndpoints" => "regional",
        "s3UsEast1RegionalEndpoints" => "regional",
        "connectTimeoutInMillis" => 1100,
        "tlsNegotiationTimeoutInMillis" => 1100
      },
      "modes" => {
        "standard" => {
          "connectTimeoutInMillis" => {
            "override" => 3100
          },
          "tlsNegotiationTimeoutInMillis" => {
            "override" => 3100
          }
        },
        "in-region" => {
        },
        "cross-region" => {
          "connectTimeoutInMillis" => {
            "override" => 3100
          },
          "tlsNegotiationTimeoutInMillis" => {
            "override" => 3100
          }
        },
        "mobile" => {
          "connectTimeoutInMillis" => {
            "override" => 30000
          },
          "tlsNegotiationTimeoutInMillis" => {
            "override" => 30000
          }
        }
      }
    }
    # #defaults END - configuration
  end
end