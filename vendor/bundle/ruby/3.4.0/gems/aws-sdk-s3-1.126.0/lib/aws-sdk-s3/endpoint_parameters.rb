# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  # Endpoint parameters used to influence endpoints per request.
  #
  # @!attribute bucket
  #   The S3 bucket used to send the request. This is an optional parameter that will be set automatically for operations that are scoped to an S3 bucket.
  #
  #   @return [String]
  #
  # @!attribute region
  #   The AWS region used to dispatch the request.
  #
  #   @return [String]
  #
  # @!attribute use_fips
  #   When true, send this request to the FIPS-compliant regional endpoint. If the configured endpoint does not have a FIPS compliant endpoint, dispatching the request will return an error.
  #
  #   @return [Boolean]
  #
  # @!attribute use_dual_stack
  #   When true, use the dual-stack endpoint. If the configured endpoint does not support dual-stack, dispatching the request MAY return an error.
  #
  #   @return [Boolean]
  #
  # @!attribute endpoint
  #   Override the endpoint used to send this request
  #
  #   @return [String]
  #
  # @!attribute force_path_style
  #   When true, force a path-style endpoint to be used where the bucket name is part of the path.
  #
  #   @return [Boolean]
  #
  # @!attribute accelerate
  #   When true, use S3 Accelerate. NOTE: Not all regions support S3 accelerate.
  #
  #   @return [Boolean]
  #
  # @!attribute use_global_endpoint
  #   Whether the global endpoint should be used, rather then the regional endpoint for us-east-1.
  #
  #   @return [Boolean]
  #
  # @!attribute use_object_lambda_endpoint
  #   Internal parameter to use object lambda endpoint for an operation (eg: WriteGetObjectResponse)
  #
  #   @return [Boolean]
  #
  # @!attribute disable_access_points
  #   Internal parameter to disable Access Point Buckets
  #
  #   @return [Boolean]
  #
  # @!attribute disable_multi_region_access_points
  #   Whether multi-region access points (MRAP) should be disabled.
  #
  #   @return [Boolean]
  #
  # @!attribute use_arn_region
  #   When an Access Point ARN is provided and this flag is enabled, the SDK MUST use the ARN&#39;s region when constructing the endpoint instead of the client&#39;s configured region.
  #
  #   @return [Boolean]
  #
  EndpointParameters = Struct.new(
    :bucket,
    :region,
    :use_fips,
    :use_dual_stack,
    :endpoint,
    :force_path_style,
    :accelerate,
    :use_global_endpoint,
    :use_object_lambda_endpoint,
    :disable_access_points,
    :disable_multi_region_access_points,
    :use_arn_region,
  ) do
    include Aws::Structure

    # @api private
    class << self
      PARAM_MAP = {
        'Bucket' => :bucket,
        'Region' => :region,
        'UseFIPS' => :use_fips,
        'UseDualStack' => :use_dual_stack,
        'Endpoint' => :endpoint,
        'ForcePathStyle' => :force_path_style,
        'Accelerate' => :accelerate,
        'UseGlobalEndpoint' => :use_global_endpoint,
        'UseObjectLambdaEndpoint' => :use_object_lambda_endpoint,
        'DisableAccessPoints' => :disable_access_points,
        'DisableMultiRegionAccessPoints' => :disable_multi_region_access_points,
        'UseArnRegion' => :use_arn_region,
      }.freeze
    end

    def initialize(options = {})
      self[:bucket] = options[:bucket]
      self[:region] = options[:region]
      self[:use_fips] = options[:use_fips]
      self[:use_fips] = false if self[:use_fips].nil?
      if self[:use_fips].nil?
        raise ArgumentError, "Missing required EndpointParameter: :use_fips"
      end
      self[:use_dual_stack] = options[:use_dual_stack]
      self[:use_dual_stack] = false if self[:use_dual_stack].nil?
      if self[:use_dual_stack].nil?
        raise ArgumentError, "Missing required EndpointParameter: :use_dual_stack"
      end
      self[:endpoint] = options[:endpoint]
      self[:force_path_style] = options[:force_path_style]
      self[:accelerate] = options[:accelerate]
      self[:accelerate] = false if self[:accelerate].nil?
      if self[:accelerate].nil?
        raise ArgumentError, "Missing required EndpointParameter: :accelerate"
      end
      self[:use_global_endpoint] = options[:use_global_endpoint]
      self[:use_global_endpoint] = false if self[:use_global_endpoint].nil?
      if self[:use_global_endpoint].nil?
        raise ArgumentError, "Missing required EndpointParameter: :use_global_endpoint"
      end
      self[:use_object_lambda_endpoint] = options[:use_object_lambda_endpoint]
      self[:disable_access_points] = options[:disable_access_points]
      self[:disable_multi_region_access_points] = options[:disable_multi_region_access_points]
      self[:disable_multi_region_access_points] = false if self[:disable_multi_region_access_points].nil?
      if self[:disable_multi_region_access_points].nil?
        raise ArgumentError, "Missing required EndpointParameter: :disable_multi_region_access_points"
      end
      self[:use_arn_region] = options[:use_arn_region]
    end
  end
end
