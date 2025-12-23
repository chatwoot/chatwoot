# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # When an accesspoint ARN is provided for :bucket in S3 operations, this
      # plugin resolves the request endpoint from the ARN when possible.
      # @api private
      class ARN < Seahorse::Client::Plugin
        option(
          :s3_use_arn_region,
          default: true,
          doc_type: 'Boolean',
          docstring: <<-DOCS) do |cfg|
For S3 ARNs passed into the `:bucket` parameter, this option will
use the region in the ARN, allowing for cross-region requests to
be made. Set to `false` to use the client's region instead.
          DOCS
          resolve_s3_use_arn_region(cfg)
        end

        option(
          :s3_disable_multiregion_access_points,
          default: false,
          doc_type: 'Boolean',
          docstring: <<-DOCS) do |cfg|
When set to `false` this will option will raise errors when multi-region
access point ARNs are used.  Multi-region access points can potentially
result in cross region requests.
        DOCS
          resolve_s3_disable_multiregion_access_points(cfg)
        end

        class << self
          private

          def resolve_s3_use_arn_region(cfg)
            value = ENV['AWS_S3_USE_ARN_REGION'] ||
                    Aws.shared_config.s3_use_arn_region(profile: cfg.profile) ||
                    'true'
            value = Aws::Util.str_2_bool(value)
            # Raise if provided value is not true or false
            if value.nil?
              raise ArgumentError,
                    'Must provide either `true` or `false` for the '\
                    '`s3_use_arn_region` profile option or for '\
                    "ENV['AWS_S3_USE_ARN_REGION']."
            end
            value
          end

          def resolve_s3_disable_multiregion_access_points(cfg)
            value = ENV['AWS_S3_DISABLE_MULTIREGION_ACCESS_POINTS'] ||
              Aws.shared_config.s3_disable_multiregion_access_points(profile: cfg.profile) ||
              'false'
            value = Aws::Util.str_2_bool(value)
            # Raise if provided value is not true or false
            if value.nil?
              raise ArgumentError,
                    'Must provide either `true` or `false` for '\
                    's3_use_arn_region profile option or for '\
                    "ENV['AWS_S3_USE_ARN_REGION']"
            end
            value
          end
        end
      end
    end
  end
end
