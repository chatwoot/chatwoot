# frozen_string_literal: true

require 'time'

require_relative 'constants'
require_relative 'utils'
require_relative 'media_type'
require_relative 'headers'

module Rack
  # Rack::Response provides a convenient interface to create a Rack
  # response.
  #
  # It allows setting of headers and cookies, and provides useful
  # defaults (an OK response with empty headers and body).
  #
  # You can use Response#write to iteratively generate your response,
  # but note that this is buffered by Rack::Response until you call
  # +finish+.  +finish+ however can take a block inside which calls to
  # +write+ are synchronous with the Rack response.
  #
  # Your application's +call+ should end returning Response#finish.
  class Response
    def self.[](status, headers, body)
      self.new(body, status, headers)
    end

    CHUNKED = 'chunked'
    STATUS_WITH_NO_ENTITY_BODY = Utils::STATUS_WITH_NO_ENTITY_BODY

    attr_accessor :length, :status, :body
    attr_reader :headers

    # Initialize the response object with the specified +body+, +status+
    # and +headers+.
    #
    # If the +body+ is +nil+, construct an empty response object with internal
    # buffering.
    #
    # If the +body+ responds to +to_str+, assume it's a string-like object and
    # construct a buffered response object containing using that string as the
    # initial contents of the buffer.
    #
    # Otherwise it is expected +body+ conforms to the normal requirements of a
    # Rack response body, typically implementing one of +each+ (enumerable
    # body) or +call+ (streaming body).
    #
    # The +status+ defaults to +200+ which is the "OK" HTTP status code. You
    # can provide any other valid status code.
    #
    # The +headers+ must be a +Hash+ of key-value header pairs which conform to
    # the Rack specification for response headers. The key must be a +String+
    # instance and the value can be either a +String+ or +Array+ instance.
    def initialize(body = nil, status = 200, headers = {})
      @status = status.to_i

      unless headers.is_a?(Hash)
        raise ArgumentError, "Headers must be a Hash!"
      end

      @headers = Headers.new
      # Convert headers input to a plain hash with lowercase keys.
      headers.each do |k, v|
        @headers[k] = v
      end

      @writer = self.method(:append)

      @block = nil

      # Keep track of whether we have expanded the user supplied body.
      if body.nil?
        @body = []
        @buffered = true
        # Body is unspecified - it may be a buffered response, or it may be a HEAD response.
        @length = nil
      elsif body.respond_to?(:to_str)
        @body = [body]
        @buffered = true
        @length = body.to_str.bytesize
      else
        @body = body
        @buffered = nil # undetermined as of yet.
        @length = nil
      end

      yield self if block_given?
    end

    def redirect(target, status = 302)
      self.status = status
      self.location = target
    end

    def chunked?
      CHUNKED == get_header(TRANSFER_ENCODING)
    end

    def no_entity_body?
      # The response body is an enumerable body and it is not allowed to have an entity body.
      @body.respond_to?(:each) && STATUS_WITH_NO_ENTITY_BODY[@status]
    end

    # Generate a response array consistent with the requirements of the SPEC.
    # @return [Array] a 3-tuple suitable of `[status, headers, body]`
    # which is suitable to be returned from the middleware `#call(env)` method.
    def finish(&block)
      if no_entity_body?
        delete_header CONTENT_TYPE
        delete_header CONTENT_LENGTH
        close
        return [@status, @headers, []]
      else
        if block_given?
          # We don't add the content-length here as the user has provided a block that can #write additional chunks to the body.
          @block = block
          return [@status, @headers, self]
        else
          # If we know the length of the body, set the content-length header... except if we are chunked? which is a legacy special case where the body might already be encoded and thus the actual encoded body length and the content-length are likely to be different.
          if @length && !chunked?
            @headers[CONTENT_LENGTH] = @length.to_s
          end
          return [@status, @headers, @body]
        end
      end
    end

    alias to_a finish           # For *response

    def each(&callback)
      @body.each(&callback)
      @buffered = true

      if @block
        @writer = callback
        @block.call(self)
      end
    end

    # Append a chunk to the response body.
    #
    # Converts the response into a buffered response if it wasn't already.
    #
    # NOTE: Do not mix #write and direct #body access!
    #
    def write(chunk)
      buffered_body!

      @writer.call(chunk.to_s)
    end

    def close
      @body.close if @body.respond_to?(:close)
    end

    def empty?
      @block == nil && @body.empty?
    end

    def has_header?(key)
      raise ArgumentError unless key.is_a?(String)
      @headers.key?(key)
    end
    def get_header(key)
      raise ArgumentError unless key.is_a?(String)
      @headers[key]
    end
    def set_header(key, value)
      raise ArgumentError unless key.is_a?(String)
      @headers[key] = value
    end
    def delete_header(key)
      raise ArgumentError unless key.is_a?(String)
      @headers.delete key
    end

    alias :[] :get_header
    alias :[]= :set_header

    module Helpers
      def invalid?;             status < 100 || status >= 600;        end

      def informational?;       status >= 100 && status < 200;        end
      def successful?;          status >= 200 && status < 300;        end
      def redirection?;         status >= 300 && status < 400;        end
      def client_error?;        status >= 400 && status < 500;        end
      def server_error?;        status >= 500 && status < 600;        end

      def ok?;                  status == 200;                        end
      def created?;             status == 201;                        end
      def accepted?;            status == 202;                        end
      def no_content?;          status == 204;                        end
      def moved_permanently?;   status == 301;                        end
      def bad_request?;         status == 400;                        end
      def unauthorized?;        status == 401;                        end
      def forbidden?;           status == 403;                        end
      def not_found?;           status == 404;                        end
      def method_not_allowed?;  status == 405;                        end
      def not_acceptable?;      status == 406;                        end
      def request_timeout?;     status == 408;                        end
      def precondition_failed?; status == 412;                        end
      def unprocessable?;       status == 422;                        end

      def redirect?;            [301, 302, 303, 307, 308].include? status; end

      def include?(header)
        has_header?(header)
      end

      # Add a header that may have multiple values.
      #
      # Example:
      #   response.add_header 'vary', 'accept-encoding'
      #   response.add_header 'vary', 'cookie'
      #
      #   assert_equal 'accept-encoding,cookie', response.get_header('vary')
      #
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.2
      def add_header(key, value)
        raise ArgumentError unless key.is_a?(String)

        if value.nil?
          return get_header(key)
        end

        value = value.to_s

        if header = get_header(key)
          if header.is_a?(Array)
            header << value
          else
            set_header(key, [header, value])
          end
        else
          set_header(key, value)
        end
      end

      # Get the content type of the response.
      def content_type
        get_header CONTENT_TYPE
      end

      # Set the content type of the response.
      def content_type=(content_type)
        set_header CONTENT_TYPE, content_type
      end

      def media_type
        MediaType.type(content_type)
      end

      def media_type_params
        MediaType.params(content_type)
      end

      def content_length
        cl = get_header CONTENT_LENGTH
        cl ? cl.to_i : cl
      end

      def location
        get_header "location"
      end

      def location=(location)
        set_header "location", location
      end

      def set_cookie(key, value)
        add_header SET_COOKIE, Utils.set_cookie_header(key, value)
      end

      def delete_cookie(key, value = {})
        set_header(SET_COOKIE,
          Utils.delete_set_cookie_header!(
            get_header(SET_COOKIE), key, value
          )
        )
      end

      def set_cookie_header
        get_header SET_COOKIE
      end

      def set_cookie_header=(value)
        set_header SET_COOKIE, value
      end

      def cache_control
        get_header CACHE_CONTROL
      end

      def cache_control=(value)
        set_header CACHE_CONTROL, value
      end

      # Specifies that the content shouldn't be cached. Overrides `cache!` if already called.
      def do_not_cache!
        set_header CACHE_CONTROL, "no-cache, must-revalidate"
        set_header EXPIRES, Time.now.httpdate
      end

      # Specify that the content should be cached.
      # @param duration [Integer] The number of seconds until the cache expires.
      # @option directive [String] The cache control directive, one of "public", "private", "no-cache" or "no-store".
      def cache!(duration = 3600, directive: "public")
        unless headers[CACHE_CONTROL] =~ /no-cache/
          set_header CACHE_CONTROL, "#{directive}, max-age=#{duration}"
          set_header EXPIRES, (Time.now + duration).httpdate
        end
      end

      def etag
        get_header ETAG
      end

      def etag=(value)
        set_header ETAG, value
      end

    protected

      # Convert the body of this response into an internally buffered Array if possible.
      #
      # `@buffered` is a ternary value which indicates whether the body is buffered. It can be:
      # * `nil` - The body has not been buffered yet.
      # * `true` - The body is buffered as an Array instance.
      # * `false` - The body is not buffered and cannot be buffered.
      #
      # @return [Boolean] whether the body is buffered as an Array instance.
      def buffered_body!
        if @buffered.nil?
          if @body.is_a?(Array)
            # The user supplied body was an array:
            @body = @body.compact
            @length = @body.sum{|part| part.bytesize}
            @buffered = true
          elsif @body.respond_to?(:each)
            # Turn the user supplied body into a buffered array:
            body = @body
            @body = Array.new
            @buffered = true

            body.each do |part|
              @writer.call(part.to_s)
            end

            body.close if body.respond_to?(:close)
          else
            # We don't know how to buffer the user-supplied body:
            @buffered = false
          end
        end

        return @buffered
      end

      def append(chunk)
        chunk = chunk.dup unless chunk.frozen?
        @body << chunk

        if @length
          @length += chunk.bytesize
        elsif @buffered
          @length = chunk.bytesize
        end

        return chunk
      end
    end

    include Helpers

    class Raw
      include Helpers

      attr_reader :headers
      attr_accessor :status

      def initialize(status, headers)
        @status = status
        @headers = headers
      end

      def has_header?(key)
        headers.key?(key)
      end

      def get_header(key)
        headers[key]
      end

      def set_header(key, value)
        headers[key] = value
      end

      def delete_header(key)
        headers.delete(key)
      end
    end
  end
end
