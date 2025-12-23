# frozen_string_literal: true

require 'uri'

# :nocov:
begin
  require "rack/version"
rescue LoadError
  require "rack"
else
  if Rack.release >= '2.3'
    require "rack/request"
    require "rack/mock"
    require "rack/utils"
  else
    require "rack"
  end
end
# :nocov:

require 'forwardable'

require_relative 'test/cookie_jar'
require_relative 'test/utils'
require_relative 'test/methods'
require_relative 'test/uploaded_file'
require_relative 'test/version'

module Rack
  module Test
    # The default host to use for requests, when a full URI is not
    # provided.
    DEFAULT_HOST = 'example.org'.freeze

    # The default multipart boundary to use for multipart request bodies
    MULTIPART_BOUNDARY = '----------XnJLe9ZIbbGUYtzPQJ16u1'.freeze

    # The starting boundary in multipart requests
    START_BOUNDARY = "--#{MULTIPART_BOUNDARY}\r\n".freeze

    # The ending boundary in multipart requests
    END_BOUNDARY = "--#{MULTIPART_BOUNDARY}--\r\n".freeze

    # The common base class for exceptions raised by Rack::Test
    class Error < StandardError; end

    # Rack::Test::Session handles a series of requests issued to a Rack app.
    # It keeps track of the cookies for the session, and allows for setting headers
    # and a default rack environment that is used for future requests.
    #
    # Rack::Test::Session's methods are most often called through Rack::Test::Methods,
    # which will automatically build a session when it's first used.
    class Session
      extend Forwardable
      include Rack::Test::Utils

      def self.new(app, default_host = DEFAULT_HOST) # :nodoc:
        if app.is_a?(self)
          # Backwards compatibility for initializing with Rack::MockSession
          app
        else
          super
        end
      end

      # The Rack::Test::CookieJar for the cookies for the current session.
      attr_accessor :cookie_jar

      # The default host used for the session for when using paths for URIs.
      attr_reader :default_host

      # Creates a Rack::Test::Session for a given Rack app or Rack::Test::BasicSession.
      #
      # Note: Generally, you won't need to initialize a Rack::Test::Session directly.
      # Instead, you should include Rack::Test::Methods into your testing context.
      # (See README.rdoc for an example)
      #
      # The following methods are defined via metaprogramming: get, post, put, patch,
      # delete, options, and head. Each method submits a request with the given request
      # method, with the given URI and optional parameters and rack environment.
      # Examples:
      #
      #   # URI only:
      #   get("/")                   # GET /
      #   get("/?foo=bar")           # GET /?foo=bar
      #
      #   # URI and parameters
      #   get("/foo", 'bar'=>'baz')  # GET /foo?bar=baz
      #   post("/foo", 'bar'=>'baz') # POST /foo (bar=baz in request body)
      #
      #   # URI, parameters, and rack environment
      #   get("/bar", {}, 'CONTENT_TYPE'=>'foo')
      #   get("/bar", {'foo'=>'baz'}, 'HTTP_ACCEPT'=>'*')
      #
      # The above methods as well as #request and #custom_request store the Rack::Request
      # submitted in #last_request. The methods store a Rack::MockResponse based on the
      # response in #last_response. #last_response is also returned by the methods.
      # If a block is given, #last_response is also yielded to the block.
      def initialize(app, default_host = DEFAULT_HOST)
        @env = {}
        @app = app
        @after_request = []
        @default_host = default_host
        @last_request = nil
        @last_response = nil
        clear_cookies
      end

      %w[get post put patch delete options head].each do |method_name|
        class_eval(<<-END, __FILE__, __LINE__+1)
          def #{method_name}(uri, params = {}, env = {}, &block)
            custom_request('#{method_name.upcase}', uri, params, env, &block)
          end
        END
      end

      # Run a block after the each request completes.
      def after_request(&block)
        @after_request << block
      end

      # Replace the current cookie jar with an empty cookie jar.
      def clear_cookies
        @cookie_jar = CookieJar.new([], @default_host)
      end

      # Set a cookie in the current cookie jar.
      def set_cookie(cookie, uri = nil)
        cookie_jar.merge(cookie, uri)
      end

      # Return the last request issued in the session. Raises an error if no
      # requests have been sent yet.
      def last_request
        raise Error, 'No request yet. Request a page first.' unless @last_request
        @last_request
      end

      # Return the last response received in the session. Raises an error if
      # no requests have been sent yet.
      def last_response
        raise Error, 'No response yet. Request a page first.' unless @last_response
        @last_response
      end

      # Issue a request to the Rack app for the given URI and optional Rack
      # environment.  Example:
      #
      #   request "/"
      def request(uri, env = {}, &block)
        uri = parse_uri(uri, env)
        env = env_for(uri, env)
        process_request(uri, env, &block)
      end

      # Issue a request using the given HTTP verb for the given URI, with optional
      # params and rack environment.  Example:
      #
      #   custom_request "LINK", "/"
      def custom_request(verb, uri, params = {}, env = {}, &block)
        uri = parse_uri(uri, env)
        env = env_for(uri, env.merge(method: verb.to_s.upcase, params: params))
        process_request(uri, env, &block)
      end

      # Set a header to be included on all subsequent requests through the
      # session. Use a value of nil to remove a previously configured header.
      #
      # In accordance with the Rack spec, headers will be included in the Rack
      # environment hash in HTTP_USER_AGENT form.  Example:
      #
      #   header "user-agent", "Firefox"
      def header(name, value)
        name = name.upcase
        name.tr!('-', '_')
        name = "HTTP_#{name}" unless name == 'CONTENT_TYPE' || name == 'CONTENT_LENGTH'
        env(name, value)
      end

      # Set an entry in the rack environment to be included on all subsequent
      # requests through the session. Use a value of nil to remove a previously
      # value.  Example:
      #
      #   env "rack.session", {:csrf => 'token'}
      def env(name, value)
        if value.nil?
          @env.delete(name)
        else
          @env[name] = value
        end
      end

      # Set the username and password for HTTP Basic authorization, to be
      # included in subsequent requests in the HTTP_AUTHORIZATION header.
      #
      # Example:
      #   basic_authorize "bryan", "secret"
      def basic_authorize(username, password)
        encoded_login = ["#{username}:#{password}"].pack('m0')
        header('Authorization', "Basic #{encoded_login}")
      end

      alias authorize basic_authorize

      # Rack::Test will not follow any redirects automatically. This method
      # will follow the redirect returned (including setting the Referer header
      # on the new request) in the last response. If the last response was not
      # a redirect, an error will be raised.
      def follow_redirect!
        unless last_response.redirect?
          raise Error, 'Last response was not a redirect. Cannot follow_redirect!'
        end

        if last_response.status == 307
          request_method = last_request.request_method
          params = last_request.params
        else
          request_method = 'GET'
          params = {}
        end

        # Compute the next location by appending the location header with the
        # last request, as per https://tools.ietf.org/html/rfc7231#section-7.1.2
        # Adding two absolute locations returns the right-hand location
        next_location = URI.parse(last_request.url) + URI.parse(last_response['Location'])

        custom_request(
          request_method,
          next_location.to_s,
          params,
          'HTTP_REFERER' => last_request.url,
          'rack.session' => last_request.session,
          'rack.session.options' => last_request.session_options
        )
      end

      # Yield to the block, and restore the last request, last response, and
      # cookie jar to the state they were prior to block execution upon
      # exiting the block.
      def restore_state
        request = @last_request
        response = @last_response
        cookie_jar = @cookie_jar.dup
        after_request = @after_request.dup

        begin
          yield
        ensure
          @last_request = request
          @last_response = response
          @cookie_jar = cookie_jar
          @after_request = after_request
        end
      end

      private

      # :nocov:
      if !defined?(Rack::RELEASE) || Gem::Version.new(Rack::RELEASE) < Gem::Version.new('2.2.2')
        def close_body(body)
          body.close if body.respond_to?(:close)
        end
      # :nocov:
      else
        # close() gets called automatically in newer Rack versions.
        def close_body(body)
        end
      end

      # Normalize URI based on given URI/path and environment.
      def parse_uri(path, env)
        uri = URI.parse(path)
        uri.path = "/#{uri.path}" unless uri.path.start_with?('/')
        uri.host ||= @default_host
        uri.scheme ||= 'https' if env['HTTPS'] == 'on'
        uri
      end

      DEFAULT_ENV = {
        'rack.test' => true,
        'REMOTE_ADDR' => '127.0.0.1',
        'SERVER_PROTOCOL' => 'HTTP/1.0',
      }
      # :nocov:
      unless Rack.release >= '2.3'
        DEFAULT_ENV['HTTP_VERSION'] = DEFAULT_ENV['SERVER_PROTOCOL']
      end
      # :nocov:
      DEFAULT_ENV.freeze
      private_constant :DEFAULT_ENV

      # Update environment to use based on given URI.
      def env_for(uri, env)
        env = DEFAULT_ENV.merge(@env).merge!(env)

        env['HTTP_HOST'] ||= [uri.host, (uri.port if uri.port != uri.default_port)].compact.join(':')
        env['HTTPS'] = 'on' if URI::HTTPS === uri
        env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest' if env[:xhr]
        env['REQUEST_METHOD'] ||= env[:method] ? env[:method].to_s.upcase : 'GET'

        params = env.delete(:params)
        query_array = [uri.query]

        if env['REQUEST_METHOD'] == 'GET'
          # Treat params as query params
          if params
            append_query_params(query_array, params)
          end
        elsif !env.key?(:input)
          env['CONTENT_TYPE'] ||= 'application/x-www-form-urlencoded'
          params ||= {}
          multipart = env.has_key?(:multipart) ? env.delete(:multipart) : env['CONTENT_TYPE'].start_with?('multipart/')

          if params.is_a?(Hash)
            if !params.empty? && data = build_multipart(params, false, multipart)
              env[:input] = data
              env['CONTENT_LENGTH'] ||= data.length.to_s
              env['CONTENT_TYPE'] = "#{multipart_content_type(env)}; boundary=#{MULTIPART_BOUNDARY}"
            else
              env[:input] = build_nested_query(params)
            end
          else
            env[:input] = params
          end
        end

        if query_params = env.delete(:query_params)
          append_query_params(query_array, query_params)
        end
        query_array.compact!
        query_array.reject!(&:empty?)
        uri.query = query_array.join('&')

        set_cookie(env.delete(:cookie), uri) if env.key?(:cookie)

        Rack::MockRequest.env_for(uri.to_s, env)
      end

      # Append a string version of the query params to the array of query params.
      def append_query_params(query_array, query_params)
        query_params = parse_nested_query(query_params) if query_params.is_a?(String)
        query_array << build_nested_query(query_params)
      end

      # Return the multipart content type to use based on the environment.
      def multipart_content_type(env)
        requested_content_type = env['CONTENT_TYPE']
        if requested_content_type.start_with?('multipart/')
          requested_content_type
        else
          'multipart/form-data'
        end
      end

      # Submit the request with the given URI and rack environment to
      # the mock session.  Returns and potentially yields the last response.
      def process_request(uri, env)
        env['HTTP_COOKIE'] ||= cookie_jar.for(uri)
        @last_request = Rack::Request.new(env)
        status, headers, body = @app.call(env).to_a

        @last_response = MockResponse.new(status, headers, body, env['rack.errors'].flush)
        close_body(body)
        cookie_jar.merge(last_response.headers['set-cookie'], uri)
        @after_request.each(&:call)
        @last_response.finish

        yield @last_response if block_given?

        @last_response
      end
    end

    # Whether the version of rack in use handles encodings.
    def self.encoding_aware_strings?
      Rack.release >= '1.6'
    end
  end

  # For backwards compatibility with 1.1.0 and below
  MockSession = Test::Session
end
