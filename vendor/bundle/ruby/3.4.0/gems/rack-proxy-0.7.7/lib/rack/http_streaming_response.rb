require "net_http_hacked"
require "stringio"

module Rack
  # Wraps the hacked net/http in a Rack way.
  class HttpStreamingResponse
    STATUSES_WITH_NO_ENTITY_BODY = {
      204 => true,
      205 => true,
      304 => true
    }.freeze

    attr_accessor :use_ssl, :verify_mode, :read_timeout, :ssl_version, :cert, :key

    def initialize(request, host, port = nil)
      @request, @host, @port = request, host, port
    end

    def body
      self
    end

    def code
      response.code.to_i.tap do |response_code|
        STATUSES_WITH_NO_ENTITY_BODY[response_code] && close_connection
      end
    end
    # #status is deprecated
    alias_method :status, :code

    def headers
      Rack::Proxy.build_header_hash(response.to_hash)
    end

    # Can be called only once!
    def each(&block)
      return if connection_closed

      response.read_body(&block)
    ensure
      close_connection
    end

    def to_s
      @to_s ||= StringIO.new.tap { |io| each { |line| io << line } }.string
    end

    protected

    # Net::HTTPResponse
    def response
      @response ||= session.begin_request_hacked(request)
    end

    # Net::HTTP
    def session
      @session ||= Net::HTTP.new(host, port).tap do |http|
        http.use_ssl = use_ssl
        http.verify_mode = verify_mode
        http.read_timeout = read_timeout
        http.ssl_version = ssl_version if ssl_version
        http.cert = cert if cert
        http.key = key if key
        http.start
      end
    end

    private

    attr_reader :request, :host, :port

    attr_accessor :connection_closed

    def close_connection
      return if connection_closed

      session.end_request_hacked
      session.finish
      self.connection_closed = true
    end
  end
end
