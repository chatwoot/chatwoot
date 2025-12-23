# frozen_string_literal: true

require "net/http"
require "zlib"

module Sentry
  class HTTPTransport < Transport
    GZIP_ENCODING = "gzip"
    GZIP_THRESHOLD = 1024 * 30
    CONTENT_TYPE = 'application/x-sentry-envelope'

    DEFAULT_DELAY = 60
    RETRY_AFTER_HEADER = "retry-after"
    RATE_LIMIT_HEADER = "x-sentry-rate-limits"
    USER_AGENT = "sentry-ruby/#{Sentry::VERSION}"

    # The list of errors ::Net::HTTP is known to raise
    # See https://github.com/ruby/ruby/blob/b0c639f249165d759596f9579fa985cb30533de6/lib/bundler/fetcher.rb#L281-L286
    HTTP_ERRORS = [
      Timeout::Error, EOFError, SocketError, Errno::ENETDOWN, Errno::ENETUNREACH,
      Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EAGAIN,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
      Zlib::BufError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
    ].freeze


    def initialize(*args)
      super
      log_debug("Sentry HTTP Transport will connect to #{@dsn.server}") if @dsn
    end

    def send_data(data)
      encoding = ""

      if should_compress?(data)
        data = Zlib.gzip(data)
        encoding = GZIP_ENCODING
      end

      headers = {
        'Content-Type' => CONTENT_TYPE,
        'Content-Encoding' => encoding,
        'User-Agent' => USER_AGENT
      }

      auth_header = generate_auth_header
      headers['X-Sentry-Auth'] = auth_header if auth_header

      response = conn.start do |http|
        request = ::Net::HTTP::Post.new(endpoint, headers)
        request.body = data
        http.request(request)
      end

      if response.code.match?(/\A2\d{2}/)
        handle_rate_limited_response(response) if has_rate_limited_header?(response)
      elsif response.code == "429"
        log_debug("the server responded with status 429")
        handle_rate_limited_response(response)
      else
        error_info = "the server responded with status #{response.code}"
        error_info += "\nbody: #{response.body}"
        error_info += " Error in headers is: #{response['x-sentry-error']}" if response['x-sentry-error']

        raise Sentry::ExternalError, error_info
      end
    rescue SocketError, *HTTP_ERRORS => e
      on_error if respond_to?(:on_error)
      raise Sentry::ExternalError.new(e&.message)
    end

    def endpoint
      @dsn.envelope_endpoint
    end

    def generate_auth_header
      return nil unless @dsn

      now = Sentry.utc_now.to_i
      fields = {
        'sentry_version' => PROTOCOL_VERSION,
        'sentry_client' => USER_AGENT,
        'sentry_timestamp' => now,
        'sentry_key' => @dsn.public_key
      }
      fields['sentry_secret'] = @dsn.secret_key if @dsn.secret_key
      'Sentry ' + fields.map { |key, value| "#{key}=#{value}" }.join(', ')
    end

    def conn
      server = URI(@dsn.server)

      # connection respects proxy setting from @transport_configuration, or environment variables (HTTP_PROXY, HTTPS_PROXY, NO_PROXY)
      # Net::HTTP will automatically read the env vars.
      # See https://ruby-doc.org/3.2.2/stdlibs/net/Net/HTTP.html#class-Net::HTTP-label-Proxies
      connection =
        if proxy = normalize_proxy(@transport_configuration.proxy)
          ::Net::HTTP.new(server.hostname, server.port, proxy[:uri].hostname, proxy[:uri].port, proxy[:user], proxy[:password])
        else
          ::Net::HTTP.new(server.hostname, server.port)
        end

      connection.use_ssl = server.scheme == "https"
      connection.read_timeout = @transport_configuration.timeout
      connection.write_timeout = @transport_configuration.timeout if connection.respond_to?(:write_timeout)
      connection.open_timeout = @transport_configuration.open_timeout

      ssl_configuration.each do |key, value|
        connection.send("#{key}=", value)
      end

      connection
    end

    private

    def has_rate_limited_header?(headers)
      headers[RETRY_AFTER_HEADER] || headers[RATE_LIMIT_HEADER]
    end

    def handle_rate_limited_response(headers)
      rate_limits =
        if rate_limits = headers[RATE_LIMIT_HEADER]
          parse_rate_limit_header(rate_limits)
        elsif retry_after = headers[RETRY_AFTER_HEADER]
          # although Sentry doesn't send a date string back
          # based on HTTP specification, this could be a date string (instead of an integer)
          retry_after = retry_after.to_i
          retry_after = DEFAULT_DELAY if retry_after == 0

          { nil => Time.now + retry_after }
        else
          { nil => Time.now + DEFAULT_DELAY }
        end

      rate_limits.each do |category, limit|
        if current_limit = @rate_limits[category]
          if current_limit < limit
            @rate_limits[category] = limit
          end
        else
          @rate_limits[category] = limit
        end
      end
    end

    def parse_rate_limit_header(rate_limit_header)
      time = Time.now

      result = {}

      limits = rate_limit_header.split(",")
      limits.each do |limit|
        next if limit.nil? || limit.empty?

        begin
          retry_after, categories = limit.strip.split(":").first(2)
          retry_after = time + retry_after.to_i
          categories = categories.split(";")

          if categories.empty?
            result[nil] = retry_after
          else
            categories.each do |category|
              result[category] = retry_after
            end
          end
        rescue StandardError
        end
      end

      result
    end

    def should_compress?(data)
      @transport_configuration.encoding == GZIP_ENCODING && data.bytesize >= GZIP_THRESHOLD
    end

    # @param proxy [String, URI, Hash] Proxy config value passed into `config.transport`.
    #   Accepts either a URI formatted string, URI, or a hash with the `uri`, `user`, and `password` keys.
    # @return [Hash] Normalized proxy config that will be passed into `Net::HTTP`
    def normalize_proxy(proxy)
      return proxy unless proxy

      case proxy
      when String
        uri = URI(proxy)
        { uri: uri, user: uri.user, password: uri.password }
      when URI
        { uri: proxy, user: proxy.user, password: proxy.password }
      when Hash
        proxy
      end
    end

    def ssl_configuration
      configuration = {
        verify: @transport_configuration.ssl_verification,
        ca_file: @transport_configuration.ssl_ca_file
      }.merge(@transport_configuration.ssl || {})

      configuration[:verify_mode] = configuration.delete(:verify) ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      configuration
    end
  end
end
