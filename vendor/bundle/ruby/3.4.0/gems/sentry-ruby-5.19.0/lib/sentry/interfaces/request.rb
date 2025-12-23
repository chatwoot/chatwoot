# frozen_string_literal: true

module Sentry
  class RequestInterface < Interface
    REQUEST_ID_HEADERS = %w[action_dispatch.request_id HTTP_X_REQUEST_ID].freeze
    CONTENT_HEADERS = %w[CONTENT_TYPE CONTENT_LENGTH].freeze
    IP_HEADERS = [
      "REMOTE_ADDR",
      "HTTP_CLIENT_IP",
      "HTTP_X_REAL_IP",
      "HTTP_X_FORWARDED_FOR"
    ].freeze

    # See Sentry server default limits at
    # https://github.com/getsentry/sentry/blob/master/src/sentry/conf/server.py
    MAX_BODY_LIMIT = 4096 * 4

    # @return [String]
    attr_accessor :url

    # @return [String]
    attr_accessor :method

    # @return [Hash]
    attr_accessor :data

    # @return [String]
    attr_accessor :query_string

    # @return [String]
    attr_accessor :cookies

    # @return [Hash]
    attr_accessor :headers

    # @return [Hash]
    attr_accessor :env

    # @param env [Hash]
    # @param send_default_pii [Boolean]
    # @param rack_env_whitelist [Array]
    # @see Configuration#send_default_pii
    # @see Configuration#rack_env_whitelist
    def initialize(env:, send_default_pii:, rack_env_whitelist:)
      env = env.dup

      unless send_default_pii
        # need to completely wipe out ip addresses
        RequestInterface::IP_HEADERS.each do |header|
          env.delete(header)
        end
      end

      request = ::Rack::Request.new(env)

      if send_default_pii
        self.data = read_data_from(request)
        self.cookies = request.cookies
        self.query_string = request.query_string
      end

      self.url = request.scheme && request.url.split('?').first
      self.method = request.request_method

      self.headers = filter_and_format_headers(env, send_default_pii)
      self.env     = filter_and_format_env(env, rack_env_whitelist)
    end

    private

    def read_data_from(request)
      if request.form_data?
        request.POST
      elsif request.body # JSON requests, etc
        data = request.body.read(MAX_BODY_LIMIT)
        data = Utils::EncodingHelper.encode_to_utf_8(data.to_s)
        request.body.rewind
        data
      end
    rescue IOError => e
      e.message
    end

    def filter_and_format_headers(env, send_default_pii)
      env.each_with_object({}) do |(key, value), memo|
        begin
          key = key.to_s # rack env can contain symbols
          next memo['X-Request-Id'] ||= Utils::RequestId.read_from(env) if Utils::RequestId::REQUEST_ID_HEADERS.include?(key)
          next if is_server_protocol?(key, value, env["SERVER_PROTOCOL"])
          next if is_skippable_header?(key)
          next if key == "HTTP_AUTHORIZATION" && !send_default_pii

          # Rack stores headers as HTTP_WHAT_EVER, we need What-Ever
          key = key.sub(/^HTTP_/, "")
          key = key.split('_').map(&:capitalize).join('-')

          memo[key] = Utils::EncodingHelper.encode_to_utf_8(value.to_s)
        rescue StandardError => e
          # Rails adds objects to the Rack env that can sometimes raise exceptions
          # when `to_s` is called.
          # See: https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/remote_ip.rb#L134
          Sentry.logger.warn(LOGGER_PROGNAME) { "Error raised while formatting headers: #{e.message}" }
          next
        end
      end
    end

    def is_skippable_header?(key)
      key.upcase != key || # lower-case envs aren't real http headers
        key == "HTTP_COOKIE" || # Cookies don't go here, they go somewhere else
        !(key.start_with?('HTTP_') || CONTENT_HEADERS.include?(key))
    end

    # In versions < 3, Rack adds in an incorrect HTTP_VERSION key, which causes downstream
    # to think this is a Version header. Instead, this is mapped to
    # env['SERVER_PROTOCOL']. But we don't want to ignore a valid header
    # if the request has legitimately sent a Version header themselves.
    # See: https://github.com/rack/rack/blob/028438f/lib/rack/handler/cgi.rb#L29
    def is_server_protocol?(key, value, protocol_version)
      rack_version = Gem::Version.new(::Rack.release)
      return false if rack_version >= Gem::Version.new("3.0")

      key == 'HTTP_VERSION' && value == protocol_version
    end

    def filter_and_format_env(env, rack_env_whitelist)
      return env if rack_env_whitelist.empty?

      env.select do |k, _v|
        rack_env_whitelist.include? k.to_s
      end
    end
  end
end
