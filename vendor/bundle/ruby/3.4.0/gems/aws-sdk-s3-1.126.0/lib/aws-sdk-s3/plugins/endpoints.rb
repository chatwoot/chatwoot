# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE


module Aws::S3
  module Plugins
    class Endpoints < Seahorse::Client::Plugin
      option(
        :endpoint_provider,
        doc_type: 'Aws::S3::EndpointProvider',
        docstring: 'The endpoint provider used to resolve endpoints. Any '\
                   'object that responds to `#resolve_endpoint(parameters)` '\
                   'where `parameters` is a Struct similar to '\
                   '`Aws::S3::EndpointParameters`'
      ) do |cfg|
        Aws::S3::EndpointProvider.new
      end

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          # If endpoint was discovered, do not resolve or apply the endpoint.
          unless context[:discovered_endpoint]
            params = parameters_for_operation(context)
            endpoint = context.config.endpoint_provider.resolve_endpoint(params)

            context.http_request.endpoint = endpoint.url
            apply_endpoint_headers(context, endpoint.headers)
          end

          context[:endpoint_params] = params
          context[:auth_scheme] =
            Aws::Endpoints.resolve_auth_scheme(context, endpoint)

          @handler.call(context)
        end

        private

        def apply_endpoint_headers(context, headers)
          headers.each do |key, values|
            value = values
              .compact
              .map { |s| Seahorse::Util.escape_header_list_string(s.to_s) }
              .join(',')

            context.http_request.headers[key] = value
          end
        end

        def parameters_for_operation(context)
          case context.operation_name
          when :abort_multipart_upload
            Aws::S3::Endpoints::AbortMultipartUpload.build(context)
          when :complete_multipart_upload
            Aws::S3::Endpoints::CompleteMultipartUpload.build(context)
          when :copy_object
            Aws::S3::Endpoints::CopyObject.build(context)
          when :create_bucket
            Aws::S3::Endpoints::CreateBucket.build(context)
          when :create_multipart_upload
            Aws::S3::Endpoints::CreateMultipartUpload.build(context)
          when :delete_bucket
            Aws::S3::Endpoints::DeleteBucket.build(context)
          when :delete_bucket_analytics_configuration
            Aws::S3::Endpoints::DeleteBucketAnalyticsConfiguration.build(context)
          when :delete_bucket_cors
            Aws::S3::Endpoints::DeleteBucketCors.build(context)
          when :delete_bucket_encryption
            Aws::S3::Endpoints::DeleteBucketEncryption.build(context)
          when :delete_bucket_intelligent_tiering_configuration
            Aws::S3::Endpoints::DeleteBucketIntelligentTieringConfiguration.build(context)
          when :delete_bucket_inventory_configuration
            Aws::S3::Endpoints::DeleteBucketInventoryConfiguration.build(context)
          when :delete_bucket_lifecycle
            Aws::S3::Endpoints::DeleteBucketLifecycle.build(context)
          when :delete_bucket_metrics_configuration
            Aws::S3::Endpoints::DeleteBucketMetricsConfiguration.build(context)
          when :delete_bucket_ownership_controls
            Aws::S3::Endpoints::DeleteBucketOwnershipControls.build(context)
          when :delete_bucket_policy
            Aws::S3::Endpoints::DeleteBucketPolicy.build(context)
          when :delete_bucket_replication
            Aws::S3::Endpoints::DeleteBucketReplication.build(context)
          when :delete_bucket_tagging
            Aws::S3::Endpoints::DeleteBucketTagging.build(context)
          when :delete_bucket_website
            Aws::S3::Endpoints::DeleteBucketWebsite.build(context)
          when :delete_object
            Aws::S3::Endpoints::DeleteObject.build(context)
          when :delete_object_tagging
            Aws::S3::Endpoints::DeleteObjectTagging.build(context)
          when :delete_objects
            Aws::S3::Endpoints::DeleteObjects.build(context)
          when :delete_public_access_block
            Aws::S3::Endpoints::DeletePublicAccessBlock.build(context)
          when :get_bucket_accelerate_configuration
            Aws::S3::Endpoints::GetBucketAccelerateConfiguration.build(context)
          when :get_bucket_acl
            Aws::S3::Endpoints::GetBucketAcl.build(context)
          when :get_bucket_analytics_configuration
            Aws::S3::Endpoints::GetBucketAnalyticsConfiguration.build(context)
          when :get_bucket_cors
            Aws::S3::Endpoints::GetBucketCors.build(context)
          when :get_bucket_encryption
            Aws::S3::Endpoints::GetBucketEncryption.build(context)
          when :get_bucket_intelligent_tiering_configuration
            Aws::S3::Endpoints::GetBucketIntelligentTieringConfiguration.build(context)
          when :get_bucket_inventory_configuration
            Aws::S3::Endpoints::GetBucketInventoryConfiguration.build(context)
          when :get_bucket_lifecycle
            Aws::S3::Endpoints::GetBucketLifecycle.build(context)
          when :get_bucket_lifecycle_configuration
            Aws::S3::Endpoints::GetBucketLifecycleConfiguration.build(context)
          when :get_bucket_location
            Aws::S3::Endpoints::GetBucketLocation.build(context)
          when :get_bucket_logging
            Aws::S3::Endpoints::GetBucketLogging.build(context)
          when :get_bucket_metrics_configuration
            Aws::S3::Endpoints::GetBucketMetricsConfiguration.build(context)
          when :get_bucket_notification
            Aws::S3::Endpoints::GetBucketNotification.build(context)
          when :get_bucket_notification_configuration
            Aws::S3::Endpoints::GetBucketNotificationConfiguration.build(context)
          when :get_bucket_ownership_controls
            Aws::S3::Endpoints::GetBucketOwnershipControls.build(context)
          when :get_bucket_policy
            Aws::S3::Endpoints::GetBucketPolicy.build(context)
          when :get_bucket_policy_status
            Aws::S3::Endpoints::GetBucketPolicyStatus.build(context)
          when :get_bucket_replication
            Aws::S3::Endpoints::GetBucketReplication.build(context)
          when :get_bucket_request_payment
            Aws::S3::Endpoints::GetBucketRequestPayment.build(context)
          when :get_bucket_tagging
            Aws::S3::Endpoints::GetBucketTagging.build(context)
          when :get_bucket_versioning
            Aws::S3::Endpoints::GetBucketVersioning.build(context)
          when :get_bucket_website
            Aws::S3::Endpoints::GetBucketWebsite.build(context)
          when :get_object
            Aws::S3::Endpoints::GetObject.build(context)
          when :get_object_acl
            Aws::S3::Endpoints::GetObjectAcl.build(context)
          when :get_object_attributes
            Aws::S3::Endpoints::GetObjectAttributes.build(context)
          when :get_object_legal_hold
            Aws::S3::Endpoints::GetObjectLegalHold.build(context)
          when :get_object_lock_configuration
            Aws::S3::Endpoints::GetObjectLockConfiguration.build(context)
          when :get_object_retention
            Aws::S3::Endpoints::GetObjectRetention.build(context)
          when :get_object_tagging
            Aws::S3::Endpoints::GetObjectTagging.build(context)
          when :get_object_torrent
            Aws::S3::Endpoints::GetObjectTorrent.build(context)
          when :get_public_access_block
            Aws::S3::Endpoints::GetPublicAccessBlock.build(context)
          when :head_bucket
            Aws::S3::Endpoints::HeadBucket.build(context)
          when :head_object
            Aws::S3::Endpoints::HeadObject.build(context)
          when :list_bucket_analytics_configurations
            Aws::S3::Endpoints::ListBucketAnalyticsConfigurations.build(context)
          when :list_bucket_intelligent_tiering_configurations
            Aws::S3::Endpoints::ListBucketIntelligentTieringConfigurations.build(context)
          when :list_bucket_inventory_configurations
            Aws::S3::Endpoints::ListBucketInventoryConfigurations.build(context)
          when :list_bucket_metrics_configurations
            Aws::S3::Endpoints::ListBucketMetricsConfigurations.build(context)
          when :list_buckets
            Aws::S3::Endpoints::ListBuckets.build(context)
          when :list_multipart_uploads
            Aws::S3::Endpoints::ListMultipartUploads.build(context)
          when :list_object_versions
            Aws::S3::Endpoints::ListObjectVersions.build(context)
          when :list_objects
            Aws::S3::Endpoints::ListObjects.build(context)
          when :list_objects_v2
            Aws::S3::Endpoints::ListObjectsV2.build(context)
          when :list_parts
            Aws::S3::Endpoints::ListParts.build(context)
          when :put_bucket_accelerate_configuration
            Aws::S3::Endpoints::PutBucketAccelerateConfiguration.build(context)
          when :put_bucket_acl
            Aws::S3::Endpoints::PutBucketAcl.build(context)
          when :put_bucket_analytics_configuration
            Aws::S3::Endpoints::PutBucketAnalyticsConfiguration.build(context)
          when :put_bucket_cors
            Aws::S3::Endpoints::PutBucketCors.build(context)
          when :put_bucket_encryption
            Aws::S3::Endpoints::PutBucketEncryption.build(context)
          when :put_bucket_intelligent_tiering_configuration
            Aws::S3::Endpoints::PutBucketIntelligentTieringConfiguration.build(context)
          when :put_bucket_inventory_configuration
            Aws::S3::Endpoints::PutBucketInventoryConfiguration.build(context)
          when :put_bucket_lifecycle
            Aws::S3::Endpoints::PutBucketLifecycle.build(context)
          when :put_bucket_lifecycle_configuration
            Aws::S3::Endpoints::PutBucketLifecycleConfiguration.build(context)
          when :put_bucket_logging
            Aws::S3::Endpoints::PutBucketLogging.build(context)
          when :put_bucket_metrics_configuration
            Aws::S3::Endpoints::PutBucketMetricsConfiguration.build(context)
          when :put_bucket_notification
            Aws::S3::Endpoints::PutBucketNotification.build(context)
          when :put_bucket_notification_configuration
            Aws::S3::Endpoints::PutBucketNotificationConfiguration.build(context)
          when :put_bucket_ownership_controls
            Aws::S3::Endpoints::PutBucketOwnershipControls.build(context)
          when :put_bucket_policy
            Aws::S3::Endpoints::PutBucketPolicy.build(context)
          when :put_bucket_replication
            Aws::S3::Endpoints::PutBucketReplication.build(context)
          when :put_bucket_request_payment
            Aws::S3::Endpoints::PutBucketRequestPayment.build(context)
          when :put_bucket_tagging
            Aws::S3::Endpoints::PutBucketTagging.build(context)
          when :put_bucket_versioning
            Aws::S3::Endpoints::PutBucketVersioning.build(context)
          when :put_bucket_website
            Aws::S3::Endpoints::PutBucketWebsite.build(context)
          when :put_object
            Aws::S3::Endpoints::PutObject.build(context)
          when :put_object_acl
            Aws::S3::Endpoints::PutObjectAcl.build(context)
          when :put_object_legal_hold
            Aws::S3::Endpoints::PutObjectLegalHold.build(context)
          when :put_object_lock_configuration
            Aws::S3::Endpoints::PutObjectLockConfiguration.build(context)
          when :put_object_retention
            Aws::S3::Endpoints::PutObjectRetention.build(context)
          when :put_object_tagging
            Aws::S3::Endpoints::PutObjectTagging.build(context)
          when :put_public_access_block
            Aws::S3::Endpoints::PutPublicAccessBlock.build(context)
          when :restore_object
            Aws::S3::Endpoints::RestoreObject.build(context)
          when :select_object_content
            Aws::S3::Endpoints::SelectObjectContent.build(context)
          when :upload_part
            Aws::S3::Endpoints::UploadPart.build(context)
          when :upload_part_copy
            Aws::S3::Endpoints::UploadPartCopy.build(context)
          when :write_get_object_response
            Aws::S3::Endpoints::WriteGetObjectResponse.build(context)
          end
        end
      end

      def add_handlers(handlers, _config)
        handlers.add(Handler, step: :build, priority: 75)
      end
    end
  end
end
