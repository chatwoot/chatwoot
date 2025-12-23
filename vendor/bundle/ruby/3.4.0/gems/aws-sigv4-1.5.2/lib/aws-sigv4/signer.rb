# frozen_string_literal: true

require 'openssl'
require 'tempfile'
require 'time'
require 'uri'
require 'set'
require 'cgi'
require 'aws-eventstream'

module Aws
  module Sigv4

    # Utility class for creating AWS signature version 4 signature. This class
    # provides two methods for generating signatures:
    #
    # * {#sign_request} - Computes a signature of the given request, returning
    #   the hash of headers that should be applied to the request.
    #
    # * {#presign_url} - Computes a presigned request with an expiration.
    #   By default, the body of this request is not signed and the request
    #   expires in 15 minutes.
    #
    # ## Configuration
    #
    # To use the signer, you need to specify the service, region, and credentials.
    # The service name is normally the endpoint prefix to an AWS service. For
    # example:
    #
    #     ec2.us-west-1.amazonaws.com => ec2
    #
    # The region is normally the second portion of the endpoint, following
    # the service name.
    #
    #     ec2.us-west-1.amazonaws.com => us-west-1
    #
    # It is important to have the correct service and region name, or the
    # signature will be invalid.
    #
    # ## Credentials
    #
    # The signer requires credentials. You can configure the signer
    # with static credentials:
    #
    #     signer = Aws::Sigv4::Signer.new(
    #       service: 's3',
    #       region: 'us-east-1',
    #       # static credentials
    #       access_key_id: 'akid',
    #       secret_access_key: 'secret'
    #     )
    #
    # You can also provide refreshing credentials via the `:credentials_provider`.
    # If you are using the AWS SDK for Ruby, you can use any of the credential
    # classes:
    #
    #     signer = Aws::Sigv4::Signer.new(
    #       service: 's3',
    #       region: 'us-east-1',
    #       credentials_provider: Aws::InstanceProfileCredentials.new
    #     )
    #
    # Other AWS SDK for Ruby classes that can be provided via `:credentials_provider`:
    #
    # * `Aws::Credentials`
    # * `Aws::SharedCredentials`
    # * `Aws::InstanceProfileCredentials`
    # * `Aws::AssumeRoleCredentials`
    # * `Aws::ECSCredentials`
    #
    # A credential provider is any object that responds to `#credentials`
    # returning another object that responds to `#access_key_id`, `#secret_access_key`,
    # and `#session_token`.
    #
    class Signer

      @@use_crt =
        begin
          require 'aws-crt'
          true
        rescue LoadError
          false
        end

      # @overload initialize(service:, region:, access_key_id:, secret_access_key:, session_token:nil, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [String] :access_key_id
      #   @param [String] :secret_access_key
      #   @param [String] :session_token (nil)
      #
      # @overload initialize(service:, region:, credentials:, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [Credentials] :credentials Any object that responds to the following
      #     methods:
      #
      #     * `#access_key_id` => String
      #     * `#secret_access_key` => String
      #     * `#session_token` => String, nil
      #     * `#set?` => Boolean
      #
      # @overload initialize(service:, region:, credentials_provider:, **options)
      #   @param [String] :service The service signing name, e.g. 's3'.
      #   @param [String] :region The region name, e.g. 'us-east-1'.
      #   @param [#credentials] :credentials_provider An object that responds
      #     to `#credentials`, returning an object that responds to the following
      #     methods:
      #
      #     * `#access_key_id` => String
      #     * `#secret_access_key` => String
      #     * `#session_token` => String, nil
      #     * `#set?` => Boolean
      #
      # @option options [Array<String>] :unsigned_headers ([]) A list of
      #   headers that should not be signed. This is useful when a proxy
      #   modifies headers, such as 'User-Agent', invalidating a signature.
      #
      # @option options [Boolean] :uri_escape_path (true) When `true`,
      #   the request URI path is uri-escaped as part of computing the canonical
      #   request string. This is required for every service, except Amazon S3,
      #   as of late 2016.
      #
      # @option options [Boolean] :apply_checksum_header (true) When `true`,
      #   the computed content checksum is returned in the hash of signature
      #   headers. This is required for AWS Glacier, and optional for
      #   every other AWS service as of late 2016.
      #
      # @option options [Symbol] :signing_algorithm (:sigv4) The
      #   algorithm to use for signing.  :sigv4a is only supported when
      #   `aws-crt` is available.
      #
      # @option options [Boolean] :omit_session_token (false)
      #   (Supported only when `aws-crt` is available) If `true`,
      #   then security token is added to the final signing result,
      #   but is treated as "unsigned" and does not contribute
      #   to the authorization signature.
      #
      # @option options [Boolean] :normalize_path (true) (Supported only when `aws-crt` is available)
      #   When `true`, the uri paths will be normalized when building the canonical request
      def initialize(options = {})
        @service = extract_service(options)
        @region = extract_region(options)
        @credentials_provider = extract_credentials_provider(options)
        @unsigned_headers = Set.new((options.fetch(:unsigned_headers, [])).map(&:downcase))
        @unsigned_headers << 'authorization'
        @unsigned_headers << 'x-amzn-trace-id'
        @unsigned_headers << 'expect'
        @uri_escape_path = options.fetch(:uri_escape_path, true)
        @apply_checksum_header = options.fetch(:apply_checksum_header, true)
        @signing_algorithm = options.fetch(:signing_algorithm, :sigv4)
        @normalize_path = options.fetch(:normalize_path, true)
        @omit_session_token = options.fetch(:omit_session_token, false)

        if @signing_algorithm == :sigv4a && !Signer.use_crt?
          raise ArgumentError, 'You are attempting to sign a' \
' request with sigv4a which requires the `aws-crt` gem.'\
' Please install the gem or add it to your gemfile.'
        end
      end

      # @return [String]
      attr_reader :service

      # @return [String]
      attr_reader :region

      # @return [#credentials] Returns an object that responds to
      #   `#credentials`, returning an object that responds to the following
      #   methods:
      #
      #   * `#access_key_id` => String
      #   * `#secret_access_key` => String
      #   * `#session_token` => String, nil
      #   * `#set?` => Boolean
      #
      attr_reader :credentials_provider

      # @return [Set<String>] Returns a set of header names that should not be signed.
      #   All header names have been downcased.
      attr_reader :unsigned_headers

      # @return [Boolean] When `true` the `x-amz-content-sha256` header will be signed and
      #   returned in the signature headers.
      attr_reader :apply_checksum_header

      # Computes a version 4 signature signature. Returns the resultant
      # signature as a hash of headers to apply to your HTTP request. The given
      # request is not modified.
      #
      #     signature = signer.sign_request(
      #       http_method: 'PUT',
      #       url: 'https://domain.com',
      #       headers: {
      #         'Abc' => 'xyz',
      #       },
      #       body: 'body' # String or IO object
      #     )
      #
      #     # Apply the following hash of headers to your HTTP request
      #     signature.headers['host']
      #     signature.headers['x-amz-date']
      #     signature.headers['x-amz-security-token']
      #     signature.headers['x-amz-content-sha256']
      #     signature.headers['authorization']
      #
      # In addition to computing the signature headers, the canonicalized
      # request, string to sign and content sha256 checksum are also available.
      # These values are useful for debugging signature errors returned by AWS.
      #
      #     signature.canonical_request #=> "..."
      #     signature.string_to_sign #=> "..."
      #     signature.content_sha256 #=> "..."
      #
      # @param [Hash] request
      #
      # @option request [required, String] :http_method One of
      #   'GET', 'HEAD', 'PUT', 'POST', 'PATCH', or 'DELETE'
      #
      # @option request [required, String, URI::HTTPS, URI::HTTP] :url
      #   The request URI. Must be a valid HTTP or HTTPS URI.
      #
      # @option request [optional, Hash] :headers ({}) A hash of headers
      #   to sign. If the 'X-Amz-Content-Sha256' header is set, the `:body`
      #   is optional and will not be read.
      #
      # @option request [optional, String, IO] :body ('') The HTTP request body.
      #   A sha256 checksum is computed of the body unless the
      #   'X-Amz-Content-Sha256' header is set.
      #
      # @return [Signature] Return an instance of {Signature} that has
      #   a `#headers` method. The headers must be applied to your request.
      #
      def sign_request(request)

        return crt_sign_request(request) if Signer.use_crt?

        creds = fetch_credentials

        http_method = extract_http_method(request)
        url = extract_url(request)
        headers = downcase_headers(request[:headers])

        datetime = headers['x-amz-date']
        datetime ||= Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
        date = datetime[0,8]

        content_sha256 = headers['x-amz-content-sha256']
        content_sha256 ||= sha256_hexdigest(request[:body] || '')

        sigv4_headers = {}
        sigv4_headers['host'] = headers['host'] || host(url)
        sigv4_headers['x-amz-date'] = datetime
        sigv4_headers['x-amz-security-token'] = creds.session_token if creds.session_token
        sigv4_headers['x-amz-content-sha256'] ||= content_sha256 if @apply_checksum_header

        headers = headers.merge(sigv4_headers) # merge so we do not modify given headers hash

        # compute signature parts
        creq = canonical_request(http_method, url, headers, content_sha256)
        sts = string_to_sign(datetime, creq)
        sig = signature(creds.secret_access_key, date, sts)

        # apply signature
        sigv4_headers['authorization'] = [
          "AWS4-HMAC-SHA256 Credential=#{credential(creds, date)}",
          "SignedHeaders=#{signed_headers(headers)}",
          "Signature=#{sig}",
        ].join(', ')

        # Returning the signature components.
        Signature.new(
          headers: sigv4_headers,
          string_to_sign: sts,
          canonical_request: creq,
          content_sha256: content_sha256
        )
      end

      # Signs a event and returns signature headers and prior signature
      # used for next event signing.
      #
      # Headers of a sigv4 signed event message only contains 2 headers
      #   * ':chunk-signature'
      #     * computed signature of the event, binary string, 'bytes' type
      #   * ':date'
      #     * millisecond since epoch, 'timestamp' type
      #
      # Payload of the sigv4 signed event message contains eventstream encoded message
      # which is serialized based on input and protocol
      #
      # To sign events
      #
      #     headers_0, signature_0 = signer.sign_event(
      #       prior_signature, # hex-encoded string
      #       payload_0, # binary string (eventstream encoded event 0)
      #       encoder, # Aws::EventStreamEncoder
      #     )
      #
      #     headers_1, signature_1 = signer.sign_event(
      #       signature_0,
      #       payload_1, # binary string (eventstream encoded event 1)
      #       encoder
      #     )
      #
      # The initial prior_signature should be using the signature computed at initial request
      #
      # Note:
      #
      #   Since ':chunk-signature' header value has bytes type, the signature value provided
      #   needs to be a binary string instead of a hex-encoded string (like original signature
      #   V4 algorithm). Thus, when returning signature value used for next event siging, the
      #   signature value (a binary string) used at ':chunk-signature' needs to converted to
      #   hex-encoded string using #unpack
      def sign_event(prior_signature, payload, encoder)
        # Note: CRT does not currently provide event stream signing, so we always use the ruby implementation.
        creds = fetch_credentials
        time = Time.now
        headers = {}

        datetime = time.utc.strftime("%Y%m%dT%H%M%SZ")
        date = datetime[0,8]
        headers[':date'] = Aws::EventStream::HeaderValue.new(value: time.to_i * 1000, type: 'timestamp')

        sts = event_string_to_sign(datetime, headers, payload, prior_signature, encoder)
        sig = event_signature(creds.secret_access_key, date, sts)

        headers[':chunk-signature'] = Aws::EventStream::HeaderValue.new(value: sig, type: 'bytes')

        # Returning signed headers and signature value in hex-encoded string
        [headers, sig.unpack('H*').first]
      end

      # Signs a URL with query authentication. Using query parameters
      # to authenticate requests is useful when you want to express a
      # request entirely in a URL. This method is also referred as
      # presigning a URL.
      #
      # See [Authenticating Requests: Using Query Parameters (AWS Signature Version 4)](http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html) for more information.
      #
      # To generate a presigned URL, you must provide a HTTP URI and
      # the http method.
      #
      #     url = signer.presign_url(
      #       http_method: 'GET',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       expires_in: 60
      #     )
      #
      # By default, signatures are valid for 15 minutes. You can specify
      # the number of seconds for the URL to expire in.
      #
      #     url = signer.presign_url(
      #       http_method: 'GET',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       expires_in: 3600 # one hour
      #     )
      #
      # You can provide a hash of headers that you plan to send with the
      # request. Every 'X-Amz-*' header you plan to send with the request
      # **must** be provided, or the signature is invalid. Other headers
      # are optional, but should be provided for security reasons.
      #
      #     url = signer.presign_url(
      #       http_method: 'PUT',
      #       url: 'https://my-bucket.s3-us-east-1.amazonaws.com/key',
      #       headers: {
      #         'X-Amz-Meta-Custom' => 'metadata'
      #       }
      #     )
      #
      # @option options [required, String] :http_method The HTTP request method,
      #   e.g. 'GET', 'HEAD', 'PUT', 'POST', 'PATCH', or 'DELETE'.
      #
      # @option options [required, String, HTTPS::URI, HTTP::URI] :url
      #   The URI to sign.
      #
      # @option options [Hash] :headers ({}) Headers that should
      #   be signed and sent along with the request. All x-amz-*
      #   headers must be present during signing. Other
      #   headers are optional.
      #
      # @option options [Integer<Seconds>] :expires_in (900)
      #   How long the presigned URL should be valid for. Defaults
      #   to 15 minutes (900 seconds).
      #
      # @option options [optional, String, IO] :body
      #   If the `:body` is set, then a SHA256 hexdigest will be computed of the body.
      #   If `:body_digest` is set, this option is ignored. If neither are set, then
      #   the `:body_digest` will be computed of the empty string.
      #
      # @option options [optional, String] :body_digest
      #   The SHA256 hexdigest of the request body. If you wish to send the presigned
      #   request without signing the body, you can pass 'UNSIGNED-PAYLOAD' as the
      #   `:body_digest` in place of passing `:body`.
      #
      # @option options [Time] :time (Time.now) Time of the signature.
      #   You should only set this value for testing.
      #
      # @return [HTTPS::URI, HTTP::URI]
      #
      def presign_url(options)

        return crt_presign_url(options) if Signer.use_crt?

        creds = fetch_credentials

        http_method = extract_http_method(options)
        url = extract_url(options)

        headers = downcase_headers(options[:headers])
        headers['host'] ||= host(url)

        datetime = headers['x-amz-date']
        datetime ||= (options[:time] || Time.now).utc.strftime("%Y%m%dT%H%M%SZ")
        date = datetime[0,8]

        content_sha256 = headers['x-amz-content-sha256']
        content_sha256 ||= options[:body_digest]
        content_sha256 ||= sha256_hexdigest(options[:body] || '')

        params = {}
        params['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256'
        params['X-Amz-Credential'] = credential(creds, date)
        params['X-Amz-Date'] = datetime
        params['X-Amz-Expires'] = extract_expires_in(options)
        params['X-Amz-Security-Token'] = creds.session_token if creds.session_token
        params['X-Amz-SignedHeaders'] = signed_headers(headers)

        params = params.map do |key, value|
          "#{uri_escape(key)}=#{uri_escape(value)}"
        end.join('&')

        if url.query
          url.query += '&' + params
        else
          url.query = params
        end

        creq = canonical_request(http_method, url, headers, content_sha256)
        sts = string_to_sign(datetime, creq)
        url.query += '&X-Amz-Signature=' + signature(creds.secret_access_key, date, sts)
        url
      end

      private

      def canonical_request(http_method, url, headers, content_sha256)
        [
          http_method,
          path(url),
          normalized_querystring(url.query || ''),
          canonical_headers(headers) + "\n",
          signed_headers(headers),
          content_sha256,
        ].join("\n")
      end

      def string_to_sign(datetime, canonical_request)
        [
          'AWS4-HMAC-SHA256',
          datetime,
          credential_scope(datetime[0,8]),
          sha256_hexdigest(canonical_request),
        ].join("\n")
      end

      # Compared to original #string_to_sign at signature v4 algorithm
      # there is no canonical_request concept for an eventstream event,
      # instead, an event contains headers and payload two parts, and
      # they will be used for computing digest in #event_string_to_sign
      #
      # Note:
      #   While headers need to be encoded under eventstream format,
      #   payload used is already eventstream encoded (event without signature),
      #   thus no extra encoding is needed.
      def event_string_to_sign(datetime, headers, payload, prior_signature, encoder)
        encoded_headers = encoder.encode_headers(
          Aws::EventStream::Message.new(headers: headers, payload: payload)
        )
        [
          "AWS4-HMAC-SHA256-PAYLOAD",
          datetime,
          credential_scope(datetime[0,8]),
          prior_signature,
          sha256_hexdigest(encoded_headers),
          sha256_hexdigest(payload)
        ].join("\n")
      end

      def credential_scope(date)
        [
          date,
          @region,
          @service,
          'aws4_request',
        ].join('/')
      end

      def credential(credentials, date)
        "#{credentials.access_key_id}/#{credential_scope(date)}"
      end

      def signature(secret_access_key, date, string_to_sign)
        k_date = hmac("AWS4" + secret_access_key, date)
        k_region = hmac(k_date, @region)
        k_service = hmac(k_region, @service)
        k_credentials = hmac(k_service, 'aws4_request')
        hexhmac(k_credentials, string_to_sign)
      end

      # Comparing to original signature v4 algorithm,
      # returned signature is a binary string instread of
      # hex-encoded string. (Since ':chunk-signature' requires
      # 'bytes' type)
      #
      # Note:
      #   converting signature from binary string to hex-encoded
      #   string is handled at #sign_event instead. (Will be used
      #   as next prior signature for event signing)
      def event_signature(secret_access_key, date, string_to_sign)
        k_date = hmac("AWS4" + secret_access_key, date)
        k_region = hmac(k_date, @region)
        k_service = hmac(k_region, @service)
        k_credentials = hmac(k_service, 'aws4_request')
        hmac(k_credentials, string_to_sign)
      end


      def path(url)
        path = url.path
        path = '/' if path == ''
        if @uri_escape_path
          uri_escape_path(path)
        else
          path
        end
      end

      def normalized_querystring(querystring)
        params = querystring.split('&')
        params = params.map { |p| p.match(/=/) ? p : p + '=' }
        # From: https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
        # Sort the parameter names by character code point in ascending order.
        # Parameters with duplicate names should be sorted by value.
        #
        # Default sort <=> in JRuby will swap members
        # occasionally when <=> is 0 (considered still sorted), but this
        # causes our normalized query string to not match the sent querystring.
        # When names match, we then sort by their values.  When values also
        # match then we sort by their original order
        params.each.with_index.sort do |a, b|
          a, a_offset = a
          b, b_offset = b
          a_name, a_value = a.split('=')
          b_name, b_value = b.split('=')
          if a_name == b_name
            if a_value == b_value
              a_offset <=> b_offset
            else
              a_value <=> b_value
            end
          else
            a_name <=> b_name
          end
        end.map(&:first).join('&')
      end

      def signed_headers(headers)
        headers.inject([]) do |signed_headers, (header, _)|
          if @unsigned_headers.include?(header)
            signed_headers
          else
            signed_headers << header
          end
        end.sort.join(';')
      end

      def canonical_headers(headers)
        headers = headers.inject([]) do |hdrs, (k,v)|
          if @unsigned_headers.include?(k)
            hdrs
          else
            hdrs << [k,v]
          end
        end
        headers = headers.sort_by(&:first)
        headers.map{|k,v| "#{k}:#{canonical_header_value(v.to_s)}" }.join("\n")
      end

      def canonical_header_value(value)
        value.gsub(/\s+/, ' ').strip
      end

      def host(uri)
        # Handles known and unknown URI schemes; default_port nil when unknown.
        if uri.default_port == uri.port
          uri.host
        else
          "#{uri.host}:#{uri.port}"
        end
      end

      # @param [File, Tempfile, IO#read, String] value
      # @return [String<SHA256 Hexdigest>]
      def sha256_hexdigest(value)
        if (File === value || Tempfile === value) && !value.path.nil? && File.exist?(value.path)
          OpenSSL::Digest::SHA256.file(value).hexdigest
        elsif value.respond_to?(:read)
          sha256 = OpenSSL::Digest::SHA256.new
          loop do
            chunk = value.read(1024 * 1024) # 1MB
            break unless chunk
            sha256.update(chunk)
          end
          value.rewind
          sha256.hexdigest
        else
          OpenSSL::Digest::SHA256.hexdigest(value)
        end
      end

      def hmac(key, value)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
      end

      def hexhmac(key, value)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, value)
      end

      def extract_service(options)
        if options[:service]
          options[:service]
        else
          msg = "missing required option :service"
          raise ArgumentError, msg
        end
      end

      def extract_region(options)
        if options[:region]
          options[:region]
        else
          raise Errors::MissingRegionError
        end
      end

      def extract_credentials_provider(options)
        if options[:credentials_provider]
          options[:credentials_provider]
        elsif options.key?(:credentials) || options.key?(:access_key_id)
          StaticCredentialsProvider.new(options)
        else
          raise Errors::MissingCredentialsError
        end
      end

      def extract_http_method(request)
        if request[:http_method]
          request[:http_method].upcase
        else
          msg = "missing required option :http_method"
          raise ArgumentError, msg
        end
      end

      def extract_url(request)
        if request[:url]
          URI.parse(request[:url].to_s)
        else
          msg = "missing required option :url"
          raise ArgumentError, msg
        end
      end

      def downcase_headers(headers)
        (headers || {}).to_hash.inject({}) do |hash, (key, value)|
          hash[key.downcase] = value
          hash
        end
      end

      def extract_expires_in(options)
        case options[:expires_in]
        when nil then 900.to_s
        when Integer then options[:expires_in].to_s
        else
          msg = "expected :expires_in to be a number of seconds"
          raise ArgumentError, msg
        end
      end

      def uri_escape(string)
        self.class.uri_escape(string)
      end

      def uri_escape_path(string)
        self.class.uri_escape_path(string)
      end


      def fetch_credentials
        credentials = @credentials_provider.credentials
        if credentials_set?(credentials)
          credentials
        else
          raise Errors::MissingCredentialsError,
          'unable to sign request without credentials set'
        end
      end

      # Returns true if credentials are set (not nil or empty)
      # Credentials may not implement the Credentials interface
      # and may just be credential like Client response objects
      # (eg those returned by sts#assume_role)
      def credentials_set?(credentials)
        !credentials.access_key_id.nil? &&
          !credentials.access_key_id.empty? &&
          !credentials.secret_access_key.nil? &&
          !credentials.secret_access_key.empty?
      end

      ### CRT Code

      # the credentials used by CRT must be a
      # CRT StaticCredentialsProvider object
      def crt_fetch_credentials
        creds = fetch_credentials
        Aws::Crt::Auth::StaticCredentialsProvider.new(
          creds.access_key_id,
          creds.secret_access_key,
          creds.session_token
        )
      end

      def crt_sign_request(request)
        creds = crt_fetch_credentials
        http_method = extract_http_method(request)
        url = extract_url(request)
        headers = downcase_headers(request[:headers])

        datetime =
          if headers.include? 'x-amz-date'
            Time.parse(headers.delete('x-amz-date'))
          end

        content_sha256 = headers.delete('x-amz-content-sha256')
        content_sha256 ||= sha256_hexdigest(request[:body] || '')

        sigv4_headers = {}
        sigv4_headers['host'] = headers['host'] || host(url)

        # Modify the user-agent to add usage of crt-signer
        # This should be temporary during developer preview only
        if headers.include? 'user-agent'
          headers['user-agent'] = "#{headers['user-agent']} crt-signer/#{@signing_algorithm}/#{Aws::Sigv4::VERSION}"
          sigv4_headers['user-agent'] = headers['user-agent']
        end

        headers = headers.merge(sigv4_headers) # merge so we do not modify given headers hash

        config = Aws::Crt::Auth::SigningConfig.new(
          algorithm: @signing_algorithm,
          signature_type: :http_request_headers,
          region: @region,
          service: @service,
          date: datetime,
          signed_body_value: content_sha256,
          signed_body_header_type: @apply_checksum_header ?
                                     :sbht_content_sha256 : :sbht_none,
          credentials: creds,
          unsigned_headers: @unsigned_headers,
          use_double_uri_encode: @uri_escape_path,
          should_normalize_uri_path: @normalize_path,
          omit_session_token: @omit_session_token
        )
        http_request = Aws::Crt::Http::Message.new(
          http_method, url.to_s, headers
        )
        signable = Aws::Crt::Auth::Signable.new(http_request)

        signing_result = Aws::Crt::Auth::Signer.sign_request(config, signable)

        Signature.new(
          headers: sigv4_headers.merge(
            downcase_headers(signing_result[:headers])
          ),
          string_to_sign: 'CRT_INTERNAL',
          canonical_request: 'CRT_INTERNAL',
          content_sha256: content_sha256,
          extra: {config: config, signable: signable}
        )
      end

      def crt_presign_url(options)
        creds = crt_fetch_credentials

        http_method = extract_http_method(options)
        url = extract_url(options)
        headers = downcase_headers(options[:headers])
        headers['host'] ||= host(url)

        datetime = headers.delete('x-amz-date')
        datetime ||= (options[:time] || Time.now)

        content_sha256 = headers.delete('x-amz-content-sha256')
        content_sha256 ||= options[:body_digest]
        content_sha256 ||= sha256_hexdigest(options[:body] || '')

        config = Aws::Crt::Auth::SigningConfig.new(
          algorithm: @signing_algorithm,
          signature_type: :http_request_query_params,
          region: @region,
          service: @service,
          date: datetime,
          signed_body_value: content_sha256,
          signed_body_header_type: @apply_checksum_header ?
                                     :sbht_content_sha256 : :sbht_none,
          credentials: creds,
          unsigned_headers: @unsigned_headers,
          use_double_uri_encode: @uri_escape_path,
          should_normalize_uri_path: @normalize_path,
          omit_session_token: @omit_session_token,
          expiration_in_seconds: options.fetch(:expires_in, 900)
        )
        http_request = Aws::Crt::Http::Message.new(
          http_method, url.to_s, headers
        )
        signable = Aws::Crt::Auth::Signable.new(http_request)

        signing_result = Aws::Crt::Auth::Signer.sign_request(config, signable, http_method, url.to_s)
        url = URI.parse(signing_result[:path])

        if options[:extra] && options[:extra].is_a?(Hash)
          options[:extra][:config] = config
          options[:extra][:signable] = signable
        end
        url
      end

      class << self

        def use_crt?
          @@use_crt
        end

        # @api private
        def uri_escape_path(path)
          path.gsub(/[^\/]+/) { |part| uri_escape(part) }
        end

        # @api private
        def uri_escape(string)
          if string.nil?
            nil
          else
            CGI.escape(string.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
          end
        end

      end
    end
  end
end
