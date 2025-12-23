# frozen_string_literal: true

require 'aws-sigv4'

module Aws
  module S3
    module Plugins
      # This plugin used to have a V4 signer but it was removed in favor of
      # generic Sign plugin that uses endpoint auth scheme.
      #
      # @api private
      class S3Signer < Seahorse::Client::Plugin
        option(:signature_version, 'v4')

        def add_handlers(handlers, cfg)
          case cfg.signature_version
          when 'v4' then add_v4_handlers(handlers)
          when 's3' then add_legacy_handler(handlers)
          else
            msg = "unsupported signature version `#{cfg.signature_version}'"
            raise ArgumentError, msg
          end
        end

        def add_v4_handlers(handlers)
          handlers.add(CachedBucketRegionHandler, step: :sign, priority: 60)
          handlers.add(BucketRegionErrorHandler, step: :sign, priority: 40)
        end

        def add_legacy_handler(handlers)
          # generic Sign plugin will be skipped if it sees sigv2
          handlers.add(LegacyHandler, step: :sign)
        end

        class LegacyHandler < Seahorse::Client::Handler
          def call(context)
            LegacySigner.sign(context)
            @handler.call(context)
          end
        end

        # This handler will update the http endpoint when the bucket region
        # is known/cached.
        class CachedBucketRegionHandler < Seahorse::Client::Handler
          def call(context)
            bucket = context.params[:bucket]
            check_for_cached_region(context, bucket) if bucket
            @handler.call(context)
          end

          private

          def check_for_cached_region(context, bucket)
            cached_region = S3::BUCKET_REGIONS[bucket]
            if cached_region &&
               cached_region != context.config.region &&
               !S3Signer.custom_endpoint?(context)
              context.http_request.endpoint.host = S3Signer.new_hostname(
                context, cached_region
              )
              context[:sigv4_region] = cached_region # Sign plugin will use this
            end
          end
        end

        # This handler detects when a request fails because of a mismatched bucket
        # region. It follows up by making a request to determine the correct
        # region, then finally a version 4 signed request against the correct
        # regional endpoint. This is intended for s3's global endpoint which
        # will return 400 if the bucket is not in region.
        class BucketRegionErrorHandler < Seahorse::Client::Handler
          def call(context)
            response = @handler.call(context)
            handle_region_errors(response)
          end

          private

          def handle_region_errors(response)
            if wrong_sigv4_region?(response) &&
               !fips_region?(response) &&
               !S3Signer.custom_endpoint?(response.context) &&
               !expired_credentials?(response)
              get_region_and_retry(response.context)
            else
              response
            end
          end

          def get_region_and_retry(context)
            actual_region = context.http_response.headers['x-amz-bucket-region']
            actual_region ||= region_from_body(context.http_response.body_contents)
            update_bucket_cache(context, actual_region)
            log_warning(context, actual_region)
            resign_with_new_region(context, actual_region)
            @handler.call(context)
          end

          def update_bucket_cache(context, actual_region)
            S3::BUCKET_REGIONS[context.params[:bucket]] = actual_region
          end

          def fips_region?(resp)
            resp.context.http_request.endpoint.host.include?('s3-fips.')
          end

          def expired_credentials?(resp)
            resp.context.http_response.body_contents.match(/<Code>ExpiredToken<\/Code>/)
          end

          def wrong_sigv4_region?(resp)
            resp.context.http_response.status_code == 400 &&
              (resp.context.http_response.headers['x-amz-bucket-region'] ||
               resp.context.http_response.body_contents.match(/<Region>.+?<\/Region>/))
          end

          def resign_with_new_region(context, actual_region)
            context.http_response.body.truncate(0)
            context.http_request.endpoint.host = S3Signer.new_hostname(
              context, actual_region
            )
            context.metadata[:redirect_region] = actual_region

            signer = Aws::Plugins::Sign.signer_for(
              context[:auth_scheme],
              context.config,
              actual_region
            )

            signer.sign(context)
          end

          def region_from_body(body)
            region = body.match(/<Region>(.+?)<\/Region>/)[1]
            if region.nil? || region == ''
              raise "couldn't get region from body: #{body}"
            else
              region
            end
          end

          def log_warning(context, actual_region)
            msg = "S3 client configured for #{context.config.region.inspect} " \
                  "but the bucket #{context.params[:bucket].inspect} is in " \
                  "#{actual_region.inspect}; Please configure the proper region " \
                  "to avoid multiple unnecessary redirects and signing attempts\n"
            if (logger = context.config.logger)
              logger.warn(msg)
            else
              warn(msg)
            end
          end
        end

        class << self
          def new_hostname(context, region)
            endpoint_params = context[:endpoint_params].dup
            endpoint_params.region = region
            endpoint_params.endpoint = nil
            endpoint =
              context.config.endpoint_provider.resolve_endpoint(endpoint_params)
            URI(endpoint.url).host
          end

          def custom_endpoint?(context)
            region = context.config.region
            partition = Aws::Endpoints::Matchers.aws_partition(region)
            endpoint = context.http_request.endpoint

            !endpoint.hostname.include?(partition['dnsSuffix']) &&
              !endpoint.hostname.include?(partition['dualStackDnsSuffix'])
          end
        end
      end
    end
  end
end
