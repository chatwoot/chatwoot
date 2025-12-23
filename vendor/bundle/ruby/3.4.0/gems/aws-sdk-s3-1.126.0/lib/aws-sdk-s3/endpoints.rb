# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::S3
  # @api private
  module Endpoints

    class AbortMultipartUpload
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class CompleteMultipartUpload
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class CopyObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class CreateBucket
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: true,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class CreateMultipartUpload
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucket
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketAnalyticsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketCors
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketEncryption
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketIntelligentTieringConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketInventoryConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketLifecycle
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketMetricsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketOwnershipControls
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketPolicy
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketReplication
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteBucketWebsite
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteObjectTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeleteObjects
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class DeletePublicAccessBlock
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketAccelerateConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketAcl
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketAnalyticsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketCors
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketEncryption
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketIntelligentTieringConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketInventoryConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketLifecycle
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketLifecycleConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketLocation
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketLogging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketMetricsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketNotification
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketNotificationConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketOwnershipControls
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketPolicy
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketPolicyStatus
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketReplication
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketRequestPayment
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketVersioning
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetBucketWebsite
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectAcl
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectAttributes
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectLegalHold
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectLockConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectRetention
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetObjectTorrent
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class GetPublicAccessBlock
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class HeadBucket
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class HeadObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListBucketAnalyticsConfigurations
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListBucketIntelligentTieringConfigurations
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListBucketInventoryConfigurations
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListBucketMetricsConfigurations
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListBuckets
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: nil,
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListMultipartUploads
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListObjectVersions
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListObjects
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListObjectsV2
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class ListParts
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketAccelerateConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketAcl
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketAnalyticsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketCors
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketEncryption
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketIntelligentTieringConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketInventoryConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketLifecycle
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketLifecycleConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketLogging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketMetricsConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketNotification
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketNotificationConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketOwnershipControls
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketPolicy
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketReplication
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketRequestPayment
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketVersioning
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutBucketWebsite
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObjectAcl
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObjectLegalHold
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObjectLockConfiguration
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObjectRetention
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutObjectTagging
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class PutPublicAccessBlock
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class RestoreObject
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class SelectObjectContent
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class UploadPart
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class UploadPartCopy
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: context.params[:bucket],
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: nil,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

    class WriteGetObjectResponse
      def self.build(context)
        unless context.config.regional_endpoint
          endpoint = context.config.endpoint.to_s
        end
        Aws::S3::EndpointParameters.new(
          bucket: nil,
          region: context.config.region,
          use_fips: context.config.use_fips_endpoint,
          use_dual_stack: context[:use_dualstack_endpoint],
          endpoint: endpoint,
          force_path_style: context.config.force_path_style,
          accelerate: context[:use_accelerate_endpoint],
          use_global_endpoint: context.config.s3_us_east_1_regional_endpoint == 'legacy',
          use_object_lambda_endpoint: true,
          disable_access_points: nil,
          disable_multi_region_access_points: context.config.s3_disable_multiregion_access_points,
          use_arn_region: context.config.s3_use_arn_region,
        )
      end
    end

  end
end
