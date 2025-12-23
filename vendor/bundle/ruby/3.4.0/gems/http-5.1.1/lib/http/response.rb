# frozen_string_literal: true

require "forwardable"

require "http/headers"
require "http/content_type"
require "http/mime_type"
require "http/response/status"
require "http/response/inflater"
require "http/cookie_jar"
require "time"

module HTTP
  class Response
    extend Forwardable

    include HTTP::Headers::Mixin

    # @return [Status]
    attr_reader :status

    # @return [String]
    attr_reader :version

    # @return [Body]
    attr_reader :body

    # @return [Request]
    attr_reader :request

    # @return [Hash]
    attr_reader :proxy_headers

    # Inits a new instance
    #
    # @option opts [Integer] :status Status code
    # @option opts [String] :version HTTP version
    # @option opts [Hash] :headers
    # @option opts [Hash] :proxy_headers
    # @option opts [HTTP::Connection] :connection
    # @option opts [String] :encoding Encoding to use when reading body
    # @option opts [String] :body
    # @option opts [HTTP::Request] request The request this is in response to.
    # @option opts [String] :uri (DEPRECATED) used to populate a missing request
    def initialize(opts)
      @version       = opts.fetch(:version)
      @request       = init_request(opts)
      @status        = HTTP::Response::Status.new(opts.fetch(:status))
      @headers       = HTTP::Headers.coerce(opts[:headers] || {})
      @proxy_headers = HTTP::Headers.coerce(opts[:proxy_headers] || {})

      if opts.include?(:body)
        @body = opts.fetch(:body)
      else
        connection = opts.fetch(:connection)
        encoding = opts[:encoding] || charset || default_encoding

        @body = Response::Body.new(connection, :encoding => encoding)
      end
    end

    # @!method reason
    #   @return (see HTTP::Response::Status#reason)
    def_delegator :@status, :reason

    # @!method code
    #   @return (see HTTP::Response::Status#code)
    def_delegator :@status, :code

    # @!method to_s
    #   (see HTTP::Response::Body#to_s)
    def_delegator :@body, :to_s
    alias to_str to_s

    # @!method readpartial
    #   (see HTTP::Response::Body#readpartial)
    def_delegator :@body, :readpartial

    # @!method connection
    #   (see HTTP::Response::Body#connection)
    def_delegator :@body, :connection

    # @!method uri
    #   @return (see HTTP::Request#uri)
    def_delegator :@request, :uri

    # Returns an Array ala Rack: `[status, headers, body]`
    #
    # @return [Array(Fixnum, Hash, String)]
    def to_a
      [status.to_i, headers.to_h, body.to_s]
    end

    # Flushes body and returns self-reference
    #
    # @return [Response]
    def flush
      body.to_s
      self
    end

    # Value of the Content-Length header.
    #
    # @return [nil] if Content-Length was not given, or it's value was invalid
    #   (not an integer, e.g. empty string or string with non-digits).
    # @return [Integer] otherwise
    def content_length
      # http://greenbytes.de/tech/webdav/rfc7230.html#rfc.section.3.3.3
      # Clause 3: "If a message is received with both a Transfer-Encoding
      # and a Content-Length header field, the Transfer-Encoding overrides the Content-Length.
      return nil if @headers.include?(Headers::TRANSFER_ENCODING)

      value = @headers[Headers::CONTENT_LENGTH]
      return nil unless value

      begin
        Integer(value)
      rescue ArgumentError
        nil
      end
    end

    # Parsed Content-Type header
    #
    # @return [HTTP::ContentType]
    def content_type
      @content_type ||= ContentType.parse headers[Headers::CONTENT_TYPE]
    end

    # @!method mime_type
    #   MIME type of response (if any)
    #   @return [String, nil]
    def_delegator :content_type, :mime_type

    # @!method charset
    #   Charset of response (if any)
    #   @return [String, nil]
    def_delegator :content_type, :charset

    def cookies
      @cookies ||= headers.get(Headers::SET_COOKIE).each_with_object CookieJar.new do |v, jar|
        jar.parse(v, uri)
      end
    end

    def chunked?
      return false unless @headers.include?(Headers::TRANSFER_ENCODING)

      encoding = @headers.get(Headers::TRANSFER_ENCODING)

      # TODO: "chunked" is frozen in the request writer. How about making it accessible?
      encoding.last == "chunked"
    end

    # Parse response body with corresponding MIME type adapter.
    #
    # @param type [#to_s] Parse as given MIME type.
    # @raise (see MimeType.[])
    # @return [Object]
    def parse(type = nil)
      MimeType[type || mime_type].decode to_s
    end

    # Inspect a response
    def inspect
      "#<#{self.class}/#{@version} #{code} #{reason} #{headers.to_h.inspect}>"
    end

    private

    def default_encoding
      return Encoding::UTF_8 if mime_type == "application/json"

      Encoding::BINARY
    end

    # Initialize an HTTP::Request from options.
    #
    # @return [HTTP::Request]
    def init_request(opts)
      raise ArgumentError, ":uri is for backwards compatibilty and conflicts with :request" \
        if opts[:request] && opts[:uri]

      # For backwards compatibilty
      if opts[:uri]
        HTTP::Request.new(:uri => opts[:uri], :verb => :get)
      else
        opts.fetch(:request)
      end
    end
  end
end
