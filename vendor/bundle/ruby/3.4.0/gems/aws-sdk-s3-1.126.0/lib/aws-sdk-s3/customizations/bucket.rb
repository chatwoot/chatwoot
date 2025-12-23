# frozen_string_literal: true

require 'uri'

module Aws
  module S3
    class Bucket
      # Deletes all objects and versioned objects from this bucket
      #
      # @example
      #
      #   bucket.clear!
      #
      # @return [void]
      def clear!
        object_versions.batch_delete!
      end

      # Deletes all objects and versioned objects from this bucket and
      # then deletes the bucket.
      #
      # @example
      #
      #   bucket.delete!
      #
      # @option options [Integer] :max_attempts (3) Maximum number of times to
      #   attempt to delete the empty bucket before raising
      #   `Aws::S3::Errors::BucketNotEmpty`.
      #
      # @option options [Float] :initial_wait (1.3) Seconds to wait before
      #   retrying the call to delete the bucket, exponentially increased for
      #   each attempt.
      #
      # @return [void]
      def delete!(options = {})
        options = {
          initial_wait: 1.3,
          max_attempts: 3
        }.merge(options)

        attempts = 0
        begin
          clear!
          delete
        rescue Errors::BucketNotEmpty
          attempts += 1
          raise if attempts >= options[:max_attempts]

          Kernel.sleep(options[:initial_wait]**attempts)
          retry
        end
      end

      # Returns a public URL for this bucket.
      #
      # @example
      #
      #   bucket = s3.bucket('bucket-name')
      #   bucket.url
      #   #=> "https://bucket-name.s3.amazonaws.com"
      #
      # It will also work when provided an Access Point ARN.
      #
      # @example
      #
      #   bucket = s3.bucket(
      #     'arn:aws:s3:us-east-1:123456789012:accesspoint:myendpoint'
      #   )
      #   bucket.url
      #   #=> "https://myendpoint-123456789012.s3-accesspoint.us-west-2.amazonaws.com"
      #
      # You can pass `virtual_host: true` to use the bucket name as the
      # host name.
      #
      #     bucket = s3.bucket('my-bucket.com')
      #     bucket.url(virtual_host: true)
      #     #=> "http://my-bucket.com"
      #
      # @option options [Boolean] :virtual_host (false) When `true`,
      #   the bucket name will be used as the host name. This is useful
      #   when you have a CNAME configured for this bucket.
      #
      # @option options [Boolean] :secure (true) When `false`, http
      #   will be used with virtual_host.  This is required when
      #   the bucket name has a dot (.) in it.
      #
      # @return [String] the URL for this bucket.
      def url(options = {})
        if options[:virtual_host]
          scheme = options.fetch(:secure, true) ? 'https' : 'http'
          "#{scheme}://#{name}"
        else
          # Taken from Aws::S3::Endpoints module
          unless client.config.regional_endpoint
            endpoint = client.config.endpoint.to_s
          end
          params = Aws::S3::EndpointParameters.new(
            bucket: name,
            region: client.config.region,
            use_fips: client.config.use_fips_endpoint,
            use_dual_stack: client.config.use_dualstack_endpoint,
            endpoint: endpoint,
            force_path_style: client.config.force_path_style,
            accelerate: client.config.use_accelerate_endpoint,
            use_global_endpoint: client.config.s3_us_east_1_regional_endpoint == 'legacy',
            use_object_lambda_endpoint: nil,
            disable_access_points: nil,
            disable_multi_region_access_points: client.config.s3_disable_multiregion_access_points,
            use_arn_region: client.config.s3_use_arn_region,
          )
          endpoint = Aws::S3::EndpointProvider.new.resolve_endpoint(params)
          endpoint.url
        end
      end

      # Creates a {PresignedPost} that makes it easy to upload a file from
      # a web browser direct to Amazon S3 using an HTML post form with
      # a file field.
      #
      # See the {PresignedPost} documentation for more information.
      # @note You must specify `:key` or `:key_starts_with`. All other options
      #   are optional.
      # @option (see PresignedPost#initialize)
      # @return [PresignedPost]
      # @see PresignedPost
      def presigned_post(options = {})
        PresignedPost.new(
          client.config.credentials,
          client.config.region,
          name,
          { url: url }.merge(options)
        )
      end

      # @api private
      def load
        @data = Aws::Plugins::UserAgent.feature('resource') do
          client.list_buckets.buckets.find { |b| b.name == name }
        end
        raise "unable to load bucket #{name}" if @data.nil?

        self
      end
    end
  end
end
