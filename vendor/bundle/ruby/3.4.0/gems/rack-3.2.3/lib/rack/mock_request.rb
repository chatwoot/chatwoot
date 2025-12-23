# frozen_string_literal: true

require 'uri'
require 'stringio'

require_relative 'constants'
require_relative 'mock_response'

module Rack
  # Rack::MockRequest helps testing your Rack application without
  # actually using HTTP.
  #
  # After performing a request on a URL with get/post/put/patch/delete, it
  # returns a MockResponse with useful helper methods for effective
  # testing.
  #
  # You can pass a hash with additional configuration to the
  # get/post/put/patch/delete.
  # <tt>:input</tt>:: A String or IO-like to be used as rack.input.
  # <tt>:fatal</tt>:: Raise a FatalWarning if the app writes to rack.errors.
  # <tt>:lint</tt>:: If true, wrap the application in a Rack::Lint.

  class MockRequest
    class FatalWarning < RuntimeError
    end

    class FatalWarner
      def puts(warning)
        raise FatalWarning, warning
      end

      def write(warning)
        raise FatalWarning, warning
      end

      def flush
      end

      def string
        ""
      end
    end

    def initialize(app)
      @app = app
    end

    # Make a GET request and return a MockResponse. See #request.
    def get(uri, opts = {})     request(GET, uri, opts)     end
    # Make a POST request and return a MockResponse. See #request.
    def post(uri, opts = {})    request(POST, uri, opts)    end
    # Make a PUT request and return a MockResponse. See #request.
    def put(uri, opts = {})     request(PUT, uri, opts)     end
    # Make a PATCH request and return a MockResponse. See #request.
    def patch(uri, opts = {})   request(PATCH, uri, opts)   end
    # Make a DELETE request and return a MockResponse. See #request.
    def delete(uri, opts = {})  request(DELETE, uri, opts)  end
    # Make a HEAD request and return a MockResponse. See #request.
    def head(uri, opts = {})    request(HEAD, uri, opts)    end
    # Make an OPTIONS request and return a MockResponse. See #request.
    def options(uri, opts = {}) request(OPTIONS, uri, opts) end

    # Make a request using the given request method for the given
    # uri to the rack application and return a MockResponse.
    # Options given are passed to MockRequest.env_for.
    def request(method = GET, uri = "", opts = {})
      env = self.class.env_for(uri, opts.merge(method: method))

      if opts[:lint]
        app = Rack::Lint.new(@app)
      else
        app = @app
      end

      errors = env[RACK_ERRORS]
      status, headers, body = app.call(env)
      MockResponse.new(status, headers, body, errors)
    ensure
      body.close if body.respond_to?(:close)
    end

    # For historical reasons, we're pinning to RFC 2396.
    # URI::Parser = URI::RFC2396_Parser
    def self.parse_uri_rfc2396(uri)
      @parser ||= URI::Parser.new
      @parser.parse(uri)
    end

    # Return the Rack environment used for a request to +uri+.
    # All options that are strings are added to the returned environment.
    # Options:
    # :fatal :: Whether to raise an exception if request outputs to rack.errors
    # :input :: The rack.input to set
    # :http_version :: The SERVER_PROTOCOL to set
    # :method :: The HTTP request method to use
    # :params :: The params to use
    # :script_name :: The SCRIPT_NAME to set
    def self.env_for(uri = "", opts = {})
      uri = parse_uri_rfc2396(uri)
      uri.path = "/#{uri.path}" unless uri.path[0] == ?/

      env = {}

      env[REQUEST_METHOD]  = (opts[:method] ? opts[:method].to_s.upcase : GET).b
      env[SERVER_NAME]     = (uri.host || "example.org").b
      env[SERVER_PORT]     = (uri.port ? uri.port.to_s : "80").b
      env[SERVER_PROTOCOL] = opts[:http_version] || 'HTTP/1.1'
      env[QUERY_STRING]    = (uri.query.to_s).b
      env[PATH_INFO]       = (uri.path).b
      env[RACK_URL_SCHEME] = (uri.scheme || "http").b
      env[HTTPS]           = (env[RACK_URL_SCHEME] == "https" ? "on" : "off").b

      env[SCRIPT_NAME] = opts[:script_name] || ""

      if opts[:fatal]
        env[RACK_ERRORS] = FatalWarner.new
      else
        env[RACK_ERRORS] = StringIO.new
      end

      if params = opts[:params]
        if env[REQUEST_METHOD] == GET
          params = Utils.parse_nested_query(params) if params.is_a?(String)
          params.update(Utils.parse_nested_query(env[QUERY_STRING]))
          env[QUERY_STRING] = Utils.build_nested_query(params)
        elsif !opts.has_key?(:input)
          opts["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
          if params.is_a?(Hash)
            if data = Rack::Multipart.build_multipart(params)
              opts[:input] = data
              opts["CONTENT_LENGTH"] ||= data.length.to_s
              opts["CONTENT_TYPE"] = "multipart/form-data; boundary=#{Rack::Multipart::MULTIPART_BOUNDARY}"
            else
              opts[:input] = Utils.build_nested_query(params)
            end
          else
            opts[:input] = params
          end
        end
      end

      rack_input = opts[:input]
      if String === rack_input
        rack_input = StringIO.new(rack_input)
      end

      if rack_input
        rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)
        env[RACK_INPUT] = rack_input

        env["CONTENT_LENGTH"] ||= env[RACK_INPUT].size.to_s if env[RACK_INPUT].respond_to?(:size)
      end

      opts.each { |field, value|
        env[field] = value if String === field
      }

      env
    end
  end
end
