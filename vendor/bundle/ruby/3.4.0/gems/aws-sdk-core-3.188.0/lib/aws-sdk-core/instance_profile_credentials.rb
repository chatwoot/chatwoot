# frozen_string_literal: true

require 'time'
require 'net/http'

module Aws
  # An auto-refreshing credential provider that loads credentials from
  # EC2 instances.
  #
  #     instance_credentials = Aws::InstanceProfileCredentials.new
  #     ec2 = Aws::EC2::Client.new(credentials: instance_credentials)
  class InstanceProfileCredentials
    include CredentialProvider
    include RefreshingCredentials

    # @api private
    class Non200Response < RuntimeError; end

    # @api private
    class TokenRetrivalError < RuntimeError; end

    # @api private
    class TokenExpiredError < RuntimeError; end

    # These are the errors we trap when attempting to talk to the
    # instance metadata service.  Any of these imply the service
    # is not present, no responding or some other non-recoverable
    # error.
    # @api private
    NETWORK_ERRORS = [
      Errno::EHOSTUNREACH,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ENETUNREACH,
      SocketError,
      Timeout::Error,
      Non200Response
    ].freeze

    # Path base for GET request for profile and credentials
    # @api private
    METADATA_PATH_BASE = '/latest/meta-data/iam/security-credentials/'.freeze

    # Path for PUT request for token
    # @api private
    METADATA_TOKEN_PATH = '/latest/api/token'.freeze

    # @param [Hash] options
    # @option options [Integer] :retries (1) Number of times to retry
    #   when retrieving credentials.
    # @option options [String] :endpoint ('http://169.254.169.254') The IMDS
    #   endpoint. This option has precedence over the :endpoint_mode.
    # @option options [String] :endpoint_mode ('IPv4') The endpoint mode for
    #   the instance metadata service. This is either 'IPv4' ('169.254.169.254')
    #   or 'IPv6' ('[fd00:ec2::254]').
    # @option options [Boolean] :disable_imds_v1 (false) Disable the use of the
    #  legacy EC2 Metadata Service v1.
    # @option options [String] :ip_address ('169.254.169.254') Deprecated. Use
    #   :endpoint instead. The IP address for the endpoint.
    # @option options [Integer] :port (80)
    # @option options [Float] :http_open_timeout (1)
    # @option options [Float] :http_read_timeout (1)
    # @option options [Numeric, Proc] :delay By default, failures are retried
    #   with exponential back-off, i.e. `sleep(1.2 ** num_failures)`. You can
    #   pass a number of seconds to sleep between failed attempts, or
    #   a Proc that accepts the number of failures.
    # @option options [IO] :http_debug_output (nil) HTTP wire
    #   traces are sent to this object.  You can specify something
    #   like $stdout.
    # @option options [Integer] :token_ttl Time-to-Live in seconds for EC2
    #   Metadata Token used for fetching Metadata Profile Credentials, defaults
    #   to 21600 seconds
    # @option options [Callable] before_refresh Proc called before
    #   credentials are refreshed. `before_refresh` is called
    #   with an instance of this object when
    #   AWS credentials are required and need to be refreshed.
    def initialize(options = {})
      @retries = options[:retries] || 1
      endpoint_mode = resolve_endpoint_mode(options)
      @endpoint = resolve_endpoint(options, endpoint_mode)
      @port = options[:port] || 80
      @disable_imds_v1 = resolve_disable_v1(options)
      # Flag for if v2 flow fails, skip future attempts
      @imds_v1_fallback = false
      @http_open_timeout = options[:http_open_timeout] || 1
      @http_read_timeout = options[:http_read_timeout] || 1
      @http_debug_output = options[:http_debug_output]
      @backoff = backoff(options[:backoff])
      @token_ttl = options[:token_ttl] || 21_600
      @token = nil
      @no_refresh_until = nil
      @async_refresh = false
      super
    end

    # @return [Integer] Number of times to retry when retrieving credentials
    #   from the instance metadata service. Defaults to 0 when resolving from
    #   the default credential chain ({Aws::CredentialProviderChain}).
    attr_reader :retries

    private

    def resolve_endpoint_mode(options)
      value = options[:endpoint_mode]
      value ||= ENV['AWS_EC2_METADATA_SERVICE_ENDPOINT_MODE']
      value ||= Aws.shared_config.ec2_metadata_service_endpoint_mode(
        profile: options[:profile]
      )
      value || 'IPv4'
    end

    def resolve_endpoint(options, endpoint_mode)
      value = options[:endpoint] || options[:ip_address]
      value ||= ENV['AWS_EC2_METADATA_SERVICE_ENDPOINT']
      value ||= Aws.shared_config.ec2_metadata_service_endpoint(
        profile: options[:profile]
      )

      return value if value

      case endpoint_mode.downcase
      when 'ipv4' then 'http://169.254.169.254'
      when 'ipv6' then 'http://[fd00:ec2::254]'
      else
        raise ArgumentError,
              ':endpoint_mode is not valid, expected IPv4 or IPv6, '\
              "got: #{endpoint_mode}"
      end
    end

    def resolve_disable_v1(options)
      value = options[:disable_imds_v1]
      value ||= ENV['AWS_EC2_METADATA_V1_DISABLED']
      value ||= Aws.shared_config.ec2_metadata_v1_disabled(
        profile: options[:profile]
      )
      value = value.to_s.downcase if value
      Aws::Util.str_2_bool(value) || false
    end

    def backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then ->(_) { sleep(backoff) }
      else ->(num_failures) { Kernel.sleep(1.2**num_failures) }
      end
    end

    def refresh
      if @no_refresh_until && @no_refresh_until > Time.now
        warn_expired_credentials
        return
      end

      # Retry loading credentials up to 3 times is the instance metadata
      # service is responding but is returning invalid JSON documents
      # in response to the GET profile credentials call.
      begin
        retry_errors([Aws::Json::ParseError], max_retries: 3) do
          c = Aws::Json.load(get_credentials.to_s)
          if empty_credentials?(@credentials)
            @credentials = Credentials.new(
              c['AccessKeyId'],
              c['SecretAccessKey'],
              c['Token']
            )
            @expiration = c['Expiration'] ? Time.iso8601(c['Expiration']) : nil
            if @expiration && @expiration < Time.now
              @no_refresh_until = Time.now + refresh_offset
              warn_expired_credentials
            end
          else
            #  credentials are already set, update them only if the new ones are not empty
            if !c['AccessKeyId'] || c['AccessKeyId'].empty?
              # error getting new credentials
              @no_refresh_until = Time.now + refresh_offset
              warn_expired_credentials
            else
              @credentials = Credentials.new(
                c['AccessKeyId'],
                c['SecretAccessKey'],
                c['Token']
              )
              @expiration = c['Expiration'] ? Time.iso8601(c['Expiration']) : nil
              if @expiration && @expiration < Time.now
                @no_refresh_until = Time.now + refresh_offset
                warn_expired_credentials
              end
            end
          end
        end
      rescue Aws::Json::ParseError
        raise Aws::Errors::MetadataParserError
      end
    end

    def get_credentials
      # Retry loading credentials a configurable number of times if
      # the instance metadata service is not responding.
      if _metadata_disabled?
        '{}'
      else
        begin
          retry_errors(NETWORK_ERRORS, max_retries: @retries) do
            open_connection do |conn|
              # attempt to fetch token to start secure flow first
              # and rescue to failover
              fetch_token(conn) unless @imds_v1_fallback
              token = @token.value if token_set?

              # disable insecure flow if we couldn't get token
              # and imds v1 is disabled
              raise TokenRetrivalError if token.nil? && @disable_imds_v1

              _get_credentials(conn, token)
            end
          end
        rescue
          '{}'
        end
      end
    end

    def fetch_token(conn)
      retry_errors(NETWORK_ERRORS, max_retries: @retries) do
        unless token_set?
          created_time = Time.now
          token_value, ttl = http_put(
            conn, METADATA_TOKEN_PATH, @token_ttl
          )
          @token = Token.new(token_value, ttl, created_time) if token_value && ttl
        end
      end
    rescue *NETWORK_ERRORS
      # token attempt failed, reset token
      # fallback to non-token mode
      @token = nil
      @imds_v1_fallback = true
    end

    # token is optional - if nil, uses v1 (insecure) flow
    def _get_credentials(conn, token)
      metadata = http_get(conn, METADATA_PATH_BASE, token)
      profile_name = metadata.lines.first.strip
      http_get(conn, METADATA_PATH_BASE + profile_name, token)
    rescue TokenExpiredError
      # Token has expired, reset it
      # The next retry should fetch it
      @token = nil
      @imds_v1_fallback = false
      raise Non200Response
    end

    def token_set?
      @token && !@token.expired?
    end

    def _metadata_disabled?
      ENV.fetch('AWS_EC2_METADATA_DISABLED', 'false').downcase == 'true'
    end

    def open_connection
      uri = URI.parse(@endpoint)
      http = Net::HTTP.new(uri.hostname || @endpoint, @port || uri.port)
      http.open_timeout = @http_open_timeout
      http.read_timeout = @http_read_timeout
      http.set_debug_output(@http_debug_output) if @http_debug_output
      http.start
      yield(http).tap { http.finish }
    end

    # GET request fetch profile and credentials
    def http_get(connection, path, token = nil)
      headers = { 'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}" }
      headers['x-aws-ec2-metadata-token'] = token if token
      response = connection.request(Net::HTTP::Get.new(path, headers))

      case response.code.to_i
      when 200
        response.body
      when 401
        raise TokenExpiredError
      else
        raise Non200Response
      end
    end

    # PUT request fetch token with ttl
    def http_put(connection, path, ttl)
      headers = {
        'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}",
        'x-aws-ec2-metadata-token-ttl-seconds' => ttl.to_s
      }
      response = connection.request(Net::HTTP::Put.new(path, headers))
      case response.code.to_i
      when 200
        [
          response.body,
          response.header['x-aws-ec2-metadata-token-ttl-seconds'].to_i
        ]
      when 400
        raise TokenRetrivalError
      else
        raise Non200Response
      end
    end

    def retry_errors(error_classes, options = {}, &_block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      rescue *error_classes
        raise unless retries < max_retries

        @backoff.call(retries)
        retries += 1
        retry
      end
    end

    def warn_expired_credentials
      warn("Attempting credential expiration extension due to a credential "\
        "service availability issue. A refresh of these credentials "\
        "will be attempted again in 5 minutes.")
    end

    def empty_credentials?(creds)
      !creds || !creds.access_key_id || creds.access_key_id.empty?
    end

    # Compute an offset for refresh with jitter
    def refresh_offset
      300 + rand(0..60)
    end

    # @api private
    # Token used to fetch IMDS profile and credentials
    class Token
      def initialize(value, ttl, created_time = Time.now)
        @ttl = ttl
        @value = value
        @created_time = created_time
      end

      # [String] token value
      attr_reader :value

      def expired?
        Time.now - @created_time > @ttl
      end
    end
  end
end
