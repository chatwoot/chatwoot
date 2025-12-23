# frozen_string_literal: true

module Rack
  # Create simple endpoints with routing rules, similar to Sinatra actions.
  #
  # Simplest example:
  #
  #   use Rack::SimpleEndpoint, '/ping_monitor' do
  #     'pong'
  #   end
  #
  # The value returned from the block will be written to the response body, so
  # the above example will return "pong" when the request path is /ping_monitor.
  #
  # HTTP verb requirements can optionally be specified:
  #
  #   use Rack::SimpleEndpoint, '/foo' => :get do
  #     'only GET requests will match'
  #   end
  #
  #   use Rack::SimpleEndpoint, '/bar' => [:get, :post] do
  #     'only GET and POST requests will match'
  #   end
  #
  # Rack::Request and Rack::Response objects are yielded to block:
  #
  #   use Rack::SimpleEndpoint, '/json' do |req, res|
  #     res['Content-Type'] = 'application/json'
  #     %({"foo": "#{req[:foo]}"})
  #   end
  #
  # When path is a Regexp, match data object is yielded as third argument to block
  #
  #   use Rack::SimpleEndpoint, %r{^/(john|paul|george|ringo)} do |req, res, match|
  #     "Hello, #{match[1]}"
  #   end
  #
  # A :pass symbol returned from block will not return a response; control will continue down the
  # Rack stack:
  #
  #   use Rack::SimpleEndpoint, '/api_key' do |req, res|
  #     req.env['myapp.user'].authorized? ? '12345' : :pass
  #   end
  #
  #   # Unauthorized access to /api_key will be handled by PublicApp
  #   run PublicApp
  class SimpleEndpoint
    def initialize(app, arg, &block)
      @app    = app
      @path   = extract_path(arg)
      @verbs  = extract_verbs(arg)
      @block  = block
    end

    def call(env)
      match = match_path(env['PATH_INFO'])
      if match && valid_method?(env['REQUEST_METHOD'])
        req, res = Request.new(env), Response.new
        body = @block.call(req, res, (match unless match == true))
        body == :pass ? @app.call(env) : (res.write(body); res.finish)
      else
        @app.call(env)
      end
    end
    
    private
      def extract_path(arg)
        arg.is_a?(Hash) ? arg.keys.first : arg
      end
      
      def extract_verbs(arg)
        arg.is_a?(Hash) ? [arg.values.first].flatten.map {|verb| verb.to_s.upcase} : []
      end
      
      def match_path(path)
        @path.is_a?(Regexp) ? @path.match(path.to_s) : @path == path.to_s
      end
      
      def valid_method?(method)
        @verbs.empty? || @verbs.include?(method)
      end
  end
end
