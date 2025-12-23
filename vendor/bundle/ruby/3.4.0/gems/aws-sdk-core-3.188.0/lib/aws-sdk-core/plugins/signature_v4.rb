# frozen_string_literal: true

require 'aws-sigv4'

module Aws
  module Plugins
    # @api private
    # Necessary to exist after endpoints 2.0
    class SignatureV4 < Seahorse::Client::Plugin

      V4_AUTH = %w[v4 v4-unsigned-payload v4-unsigned-body]

      option(:sigv4_signer) do |cfg|
        SignatureV4.build_signer(cfg)
      end

      option(:sigv4_name) do |cfg|
        signingName = if cfg.region
          Aws::Partitions::EndpointProvider.signing_service(
            cfg.region, cfg.api.metadata['endpointPrefix']
          )
        end
        signingName || cfg.api.metadata['signingName'] || cfg.api.metadata['endpointPrefix']
      end

      option(:sigv4_region) do |cfg|
        if cfg.region
          if cfg.respond_to?(:sts_regional_endpoints)
            sts_regional = cfg.sts_regional_endpoints
          end
          Aws::Partitions::EndpointProvider.signing_region(
            cfg.region, cfg.api.metadata['endpointPrefix'], sts_regional
          )
        end
      end

      option(:unsigned_operations) do |cfg|
        if cfg.api.metadata['signatureVersion'] == 'v4'
          # select operations where authtype is set and is not v4
          cfg.api.operation_names.select do |o|
            cfg.api.operation(o)['authtype'] && !V4_AUTH.include?(cfg.api.operation(o)['authtype'])
          end
        else # service is not v4 auth
          # select all operations where authtype is not v4
          # (includes operations with no explicit authtype)
          cfg.api.operation_names.select do |o|
            !V4_AUTH.include?(cfg.api.operation(o)['authtype'])
          end
        end
      end

      def add_handlers(handlers, cfg)
        if cfg.unsigned_operations.empty?
          handlers.add(Handler, step: :sign)
        else
          operations = cfg.api.operation_names - cfg.unsigned_operations
          handlers.add(Handler, step: :sign, operations: operations)
        end
      end

      class Handler < Seahorse::Client::Handler
        def call(context)
          SignatureV4.apply_signature(context: context)
          @handler.call(context)
        end
      end

      class MissingCredentialsSigner
        def sign_request(*args)
          raise Errors::MissingCredentialsError
        end
      end

      class << self

        # @api private
        def build_signer(cfg)
          if cfg.credentials && cfg.sigv4_region
            Aws::Sigv4::Signer.new(
              service: cfg.sigv4_name,
              region: cfg.sigv4_region,
              credentials_provider: cfg.credentials,
              unsigned_headers: ['content-length', 'user-agent', 'x-amzn-trace-id']
            )
          elsif cfg.credentials
            raise Errors::MissingRegionError
          elsif cfg.sigv4_region
            # Instead of raising now, we return a signer that raises only
            # if you attempt to sign a request. Some services have unsigned
            # operations and it okay to initialize clients for these services
            # without credentials. Unsigned operations have an "authtype"
            # trait of "none".
            MissingCredentialsSigner.new
          end
        end

        # @api private
        def apply_signature(options = {})
          context = apply_authtype(options[:context])
          signer = options[:signer] || context.config.sigv4_signer
          req = context.http_request

          # in case this request is being re-signed
          req.headers.delete('Authorization')
          req.headers.delete('X-Amz-Security-Token')
          req.headers.delete('X-Amz-Date')
          req.headers.delete('x-Amz-Region-Set')

          if context.config.respond_to?(:clock_skew) &&
             context.config.clock_skew &&
             context.config.correct_clock_skew

            endpoint = context.http_request.endpoint
            skew = context.config.clock_skew.clock_correction(endpoint)
            if skew.abs > 0
              req.headers['X-Amz-Date'] = (Time.now.utc + skew).strftime("%Y%m%dT%H%M%SZ")
            end
          end

          # compute the signature
          begin
            signature = signer.sign_request(
              http_method: req.http_method,
              url: req.endpoint,
              headers: req.headers,
              body: req.body
            )
          rescue Aws::Sigv4::Errors::MissingCredentialsError
            raise Aws::Errors::MissingCredentialsError
          end

          # apply signature headers
          req.headers.update(signature.headers)

          # add request metadata with signature components for debugging
          context[:canonical_request] = signature.canonical_request
          context[:string_to_sign] = signature.string_to_sign
        end

        # @api private
        def apply_authtype(context)
          if context.operation['authtype'].eql?('v4-unsigned-body') &&
             context.http_request.endpoint.scheme.eql?('https')
            context.http_request.headers['X-Amz-Content-Sha256'] ||= 'UNSIGNED-PAYLOAD'
          end
          context
        end
      end
    end
  end
end
