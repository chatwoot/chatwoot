# frozen_string_literal: true

module Aws
  module S3
    class Presigner
      # @api private
      ONE_WEEK = 60 * 60 * 24 * 7

      # @api private
      FIFTEEN_MINUTES = 60 * 15

      # @api private
      BLACKLISTED_HEADERS = [
        'accept',
        'amz-sdk-request',
        'cache-control',
        'content-length', # due to a ELB bug
        'expect',
        'from',
        'if-match',
        'if-none-match',
        'if-modified-since',
        'if-unmodified-since',
        'if-range',
        'max-forwards',
        'pragma',
        'proxy-authorization',
        'referer',
        'te',
        'user-agent'
      ].freeze

      # @option options [Client] :client Optionally provide an existing
      #   S3 client
      def initialize(options = {})
        @client = options[:client] || Aws::S3::Client.new
      end

      # Create presigned URLs for S3 operations.
      #
      # @example
      #  signer = Aws::S3::Presigner.new
      #  url = signer.presigned_url(:get_object, bucket: "bucket", key: "key")
      #
      # @param [Symbol] method Symbolized method name of the operation you want
      #   to presign.
      #
      # @option params [Integer] :expires_in (900) The number of seconds
      #   before the presigned URL expires. Defaults to 15 minutes. As signature
      #   version 4 has a maximum expiry time of one week for presigned URLs,
      #   attempts to set this value to greater than one week (604800) will
      #   raise an exception.
      #
      # @option params [Time] :time (Time.now) The starting time for when the
      #   presigned url becomes active.
      #
      # @option params [Boolean] :secure (true) When `false`, a HTTP URL
      #   is returned instead of the default HTTPS URL.
      #
      # @option params [Boolean] :virtual_host (false) When `true`, the
      #   bucket name will be used as the hostname.
      #
      # @option params [Boolean] :use_accelerate_endpoint (false) When `true`,
      #   Presigner will attempt to use accelerated endpoint.
      #
      # @option params [Array<String>] :whitelist_headers ([]) Additional
      #   headers to be included for the signed request. Certain headers beyond
      #   the authorization header could, in theory, be changed for various
      #   reasons (including but not limited to proxies) while in transit and
      #   after signing. This would lead to signature errors being returned,
      #   despite no actual problems with signing. (see BLACKLISTED_HEADERS)
      #
      # @raise [ArgumentError] Raises an ArgumentError if `:expires_in`
      #   exceeds one week.
      #
      # @return [String] a presigned url
      def presigned_url(method, params = {})
        url, _headers = _presigned_request(method, params)
        url
      end

      # Allows you to create presigned URL requests for S3 operations. This
      # method returns a tuple containing the URL and the signed X-amz-* headers
      # to be used with the presigned url.
      #
      # @example
      #  signer = Aws::S3::Presigner.new
      #  url, headers = signer.presigned_request(
      #    :get_object, bucket: "bucket", key: "key"
      #  )
      #
      # @param [Symbol] method Symbolized method name of the operation you want
      #   to presign.
      #
      # @option params [Integer] :expires_in (900) The number of seconds
      #   before the presigned URL expires. Defaults to 15 minutes. As signature
      #   version 4 has a maximum expiry time of one week for presigned URLs,
      #   attempts to set this value to greater than one week (604800) will
      #   raise an exception.
      #
      # @option params [Time] :time (Time.now) The starting time for when the
      #   presigned url becomes active.
      #
      # @option params [Boolean] :secure (true) When `false`, a HTTP URL
      #   is returned instead of the default HTTPS URL.
      #
      # @option params [Boolean] :virtual_host (false) When `true`, the
      #   bucket name will be used as the hostname. This will cause
      #   the returned URL to be 'http' and not 'https'.
      #
      # @option params [Boolean] :use_accelerate_endpoint (false) When `true`,
      #   Presigner will attempt to use accelerated endpoint.
      #
      # @option params [Array<String>] :whitelist_headers ([]) Additional
      #   headers to be included for the signed request. Certain headers beyond
      #   the authorization header could, in theory, be changed for various
      #   reasons (including but not limited to proxies) while in transit and
      #   after signing. This would lead to signature errors being returned,
      #   despite no actual problems with signing. (see BLACKLISTED_HEADERS)
      #
      # @raise [ArgumentError] Raises an ArgumentError if `:expires_in`
      #   exceeds one week.
      #
      # @return [String, Hash] A tuple with a presigned URL and headers that
      #   should be included with the request.
      def presigned_request(method, params = {})
        _presigned_request(method, params, false)
      end

      private

      def _presigned_request(method, params, hoist = true)
        virtual_host = params.delete(:virtual_host)
        time = params.delete(:time)
        unsigned_headers = unsigned_headers(params)
        secure = params.delete(:secure) != false
        expires_in = expires_in(params)

        req = @client.build_request(method, params)
        use_bucket_as_hostname(req) if virtual_host
        handle_presigned_url_context(req)

        x_amz_headers = sign_but_dont_send(
          req, expires_in, secure, time, unsigned_headers, hoist
        )
        [req.send_request.data, x_amz_headers]
      end

      def unsigned_headers(params)
        whitelist_headers = params.delete(:whitelist_headers) || []
        BLACKLISTED_HEADERS - whitelist_headers
      end

      def expires_in(params)
        if (expires_in = params.delete(:expires_in))
          if expires_in > ONE_WEEK
            raise ArgumentError,
                  "expires_in value of #{expires_in} exceeds one-week maximum."
          elsif expires_in <= 0
            raise ArgumentError,
                  "expires_in value of #{expires_in} cannot be 0 or less."
          end
          expires_in
        else
          FIFTEEN_MINUTES
        end
      end

      def use_bucket_as_hostname(req)
        req.handle(priority: 35) do |context|
          uri = context.http_request.endpoint
          uri.host = context.params[:bucket]
          uri.path.sub!("/#{context.params[:bucket]}", '')
          @handler.call(context)
        end
      end

      # Used for excluding presigned_urls from API request count.
      #
      # Store context information as early as possible, to allow
      # handlers to perform decisions based on this flag if need.
      def handle_presigned_url_context(req)
        req.handle(step: :initialize, priority: 98) do |context|
          context[:presigned_url] = true
          @handler.call(context)
        end
      end

      # @param [Seahorse::Client::Request] req
      def sign_but_dont_send(
        req, expires_in, secure, time, unsigned_headers, hoist = true
      )
        x_amz_headers = {}

        http_req = req.context.http_request

        req.handlers.remove(Aws::S3::Plugins::S3Signer::LegacyHandler)
        req.handlers.remove(Aws::Plugins::Sign::Handler)
        req.handlers.remove(Seahorse::Client::Plugins::ContentLength::Handler)

        req.handle(step: :send) do |context|
          # if an endpoint was not provided, force secure or insecure
          if context.config.regional_endpoint
            http_req.endpoint.scheme = secure ? 'https' : 'http'
            http_req.endpoint.port = secure ? 443 : 80
          end

          query = http_req.endpoint.query ? http_req.endpoint.query.split('&') : []
          http_req.headers.each do |key, value|
            next unless key =~ /^x-amz/i

            if hoist
              value = Aws::Sigv4::Signer.uri_escape(value)
              key = Aws::Sigv4::Signer.uri_escape(key)
              # hoist x-amz-* headers to the querystring
              http_req.headers.delete(key)
              query << "#{key}=#{value}"
            else
              x_amz_headers[key] = value
            end
          end
          http_req.endpoint.query = query.join('&') unless query.empty?

          auth_scheme = context[:auth_scheme]
          scheme_name = auth_scheme['name']
          region = if scheme_name == 'sigv4a'
                     auth_scheme['signingRegionSet'].first
                   else
                     auth_scheme['signingRegion']
                   end
          signer = Aws::Sigv4::Signer.new(
            service: auth_scheme['signingName'] || 's3',
            region: region || context.config.region,
            credentials_provider: context.config.credentials,
            signing_algorithm: scheme_name.to_sym,
            uri_escape_path: !!!auth_scheme['disableDoubleEncoding'],
            unsigned_headers: unsigned_headers,
            apply_checksum_header: false
          )

          url = signer.presign_url(
            http_method: http_req.http_method,
            url: http_req.endpoint,
            headers: http_req.headers,
            body_digest: 'UNSIGNED-PAYLOAD',
            expires_in: expires_in,
            time: time
          ).to_s

          Seahorse::Client::Response.new(context: context, data: url)
        end
        # Return the headers
        x_amz_headers
      end
    end
  end
end
