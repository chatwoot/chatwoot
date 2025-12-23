# frozen_string_literal: true

require 'time'
require 'net/http'

module Aws
  # A client that can query version 2 of the EC2 Instance Metadata
  class EC2Metadata
    # Path for PUT request for token
    # @api private
    METADATA_TOKEN_PATH = '/latest/api/token'.freeze

    # Raised when the PUT request is not valid. This would be thrown if
    # `token_ttl` is not an Integer.
    # @api private
    class TokenRetrievalError < RuntimeError; end

    # Token has expired, and the request can be retried with a new token.
    # @api private
    class TokenExpiredError < RuntimeError; end

    # The requested metadata path does not exist.
    # @api private
    class MetadataNotFoundError < RuntimeError; end

    # The request is not allowed or IMDS is turned off.
    # @api private
    class RequestForbiddenError < RuntimeError; end

    # Creates a client that can query version 2 of the EC2 Instance Metadata
    #   service (IMDS).
    #
    # @note Customers using containers may need to increase their hop limit
    #   to access IMDSv2.
    # @see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html#instance-metadata-transition-to-version-2
    #
    # @param [Hash] options
    # @option options [Integer] :token_ttl (21600) The session token's TTL,
    #   defaulting to 6 hours.
    # @option options [Integer] :retries (3) The number of retries for failed
    #   requests.
    # @option options [String] :endpoint ('http://169.254.169.254') The IMDS
    #   endpoint. This option has precedence over the :endpoint_mode.
    # @option options [String] :endpoint_mode ('IPv4') The endpoint mode for
    #   the instance metadata service. This is either 'IPv4'
    #   ('http://169.254.169.254') or 'IPv6' ('http://[fd00:ec2::254]').
    # @option options [Integer] :port (80) The IMDS endpoint port.
    # @option options [Integer] :http_open_timeout (1) The number of seconds to
    #   wait for the connection to open.
    # @option options [Integer] :http_read_timeout (1) The number of seconds for
    #   one chunk of data to be read.
    # @option options [IO] :http_debug_output An output stream for debugging. Do
    #   not use this in production.
    # @option options [Integer,Proc] :backoff A backoff used for retryable
    #   requests. When given an Integer, it sleeps that amount. When given a
    #   Proc, it is called with the current number of failed retries.
    def initialize(options = {})
      @token_ttl = options[:token_ttl] || 21_600
      @retries = options[:retries] || 3
      @backoff = backoff(options[:backoff])

      endpoint_mode = options[:endpoint_mode] || 'IPv4'
      @endpoint = resolve_endpoint(options[:endpoint], endpoint_mode)
      @port = options[:port] || 80

      @http_open_timeout = options[:http_open_timeout] || 1
      @http_read_timeout = options[:http_read_timeout] || 1
      @http_debug_output = options[:http_debug_output]

      @token = nil
      @mutex = Mutex.new
    end

    # Fetches a given metadata category using a String path, and returns the
    #   result as a String. A path starts with the API version (usually
    #   "/latest/"). See the instance data categories for possible paths.
    #
    # @example Fetching the instance ID
    #
    #   ec2_metadata = Aws::EC2Metadata.new
    #   ec2_metadata.get('/latest/meta-data/instance-id')
    #   => "i-023a25f10a73a0f79"
    #
    # @note This implementation always returns a String and will not parse any
    #   responses. Parsable responses may include JSON objects or directory
    #   listings, which are strings separated by line feeds (ASCII 10).
    #
    # @example Fetching and parsing JSON meta-data
    #
    #   require 'json'
    #   data = ec2_metadata.get('/latest/dynamic/instance-identity/document')
    #   JSON.parse(data)
    #   => {"accountId"=>"012345678912", ... }
    #
    # @example Fetching and parsing directory listings
    #
    #   listing = ec2_metadata.get('/latest/meta-data')
    #   listing.split(10.chr)
    #   => ["ami-id", "ami-launch-index", ...]
    #
    # @note Unlike other services, IMDS does not have a service API model. This
    #   means that we cannot confidently generate code with methods and
    #   response structures. This implementation ensures that new IMDS features
    #   are always supported by being deployed to the instance and does not
    #   require code changes.
    #
    # @see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-categories.html
    # @see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-identity-documents.html
    # @param [String] path The full path to the metadata.
    def get(path)
      retry_errors(max_retries: @retries) do
        @mutex.synchronize do
          fetch_token unless @token && !@token.expired?
        end

        open_connection do |conn|
          http_get(conn, path, @token.value)
        end
      end
    end

    private

    def resolve_endpoint(endpoint, endpoint_mode)
      return endpoint if endpoint

      case endpoint_mode.downcase
      when 'ipv4' then 'http://169.254.169.254'
      when 'ipv6' then 'http://[fd00:ec2::254]'
      else
        raise ArgumentError,
              ':endpoint_mode is not valid, expected IPv4 or IPv6, '\
              "got: #{endpoint_mode}"
      end
    end

    def fetch_token
      open_connection do |conn|
        created_time = Time.now
        token_value, token_ttl = http_put(conn, @token_ttl)
        @token = Token.new(value: token_value, ttl: token_ttl, created_time: created_time)
      end
    end

    def http_get(connection, path, token)
      headers = {
        'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}",
        'x-aws-ec2-metadata-token' => token
      }
      request = Net::HTTP::Get.new(path, headers)
      response = connection.request(request)

      case response.code.to_i
      when 200
        response.body
      when 401
        raise TokenExpiredError
      when 404
        raise MetadataNotFoundError
      end
    end

    def http_put(connection, ttl)
      headers = {
        'User-Agent' => "aws-sdk-ruby3/#{CORE_GEM_VERSION}",
        'x-aws-ec2-metadata-token-ttl-seconds' => ttl.to_s
      }
      request = Net::HTTP::Put.new(METADATA_TOKEN_PATH, headers)
      response = connection.request(request)

      case response.code.to_i
      when 200
        [
          response.body,
          response.header['x-aws-ec2-metadata-token-ttl-seconds'].to_i
        ]
      when 400
        raise TokenRetrievalError
      when 403
        raise RequestForbiddenError
      end
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

    def retry_errors(options = {}, &_block)
      max_retries = options[:max_retries]
      retries = 0
      begin
        yield
      # These errors should not be retried.
      rescue TokenRetrievalError, MetadataNotFoundError, RequestForbiddenError
        raise
      # StandardError is not ideal but it covers Net::HTTP errors.
      # https://gist.github.com/tenderlove/245188
      rescue StandardError, TokenExpiredError
        raise unless retries < max_retries

        @backoff.call(retries)
        retries += 1
        retry
      end
    end

    def backoff(backoff)
      case backoff
      when Proc then backoff
      when Numeric then ->(_) { Kernel.sleep(backoff) }
      else ->(num_failures) { Kernel.sleep(1.2**num_failures) }
      end
    end

    # @api private
    class Token
      def initialize(options = {})
        @ttl   = options[:ttl]
        @value = options[:value]
        @created_time = options[:created_time] || Time.now
      end

      # [String] Returns the token value.
      attr_reader :value

      # [Boolean] Returns true if the token expired.
      def expired?
        Time.now - @created_time > @ttl
      end
    end
  end
end
