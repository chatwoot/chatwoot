# frozen_string_literal: true

begin
  require 'json'
rescue LoadError => e
  require 'json/pure'
end

module Rack

  # <b>DEPRECATED:</b> <tt>JSONBodyParser</tt> is a drop-in replacement that is faster and more configurable.
  #
  # A Rack middleware for parsing POST/PUT body data when Content-Type is
  # not one of the standard supported types, like <tt>application/json</tt>.
  #
  # === How to use the middleware
  #
  # Example of simple +config.ru+ file:
  #
  #  require 'rack'
  #  require 'rack/contrib'
  #
  #  use ::Rack::PostBodyContentTypeParser
  #
  #  app = lambda do |env|
  #    request = Rack::Request.new(env)
  #    body = "Hello #{request.params['name']}"
  #    [200, {'Content-Type' => 'text/plain'}, [body]]
  #  end
  #
  #  run app
  #
  # Example with passing block argument:
  #
  #   use ::Rack::PostBodyContentTypeParser do |body|
  #     { 'params' => JSON.parse(body) }
  #   end
  #
  # Example with passing proc argument:
  #
  #   parser = ->(body) { { 'params' => JSON.parse(body) } }
  #   use ::Rack::PostBodyContentTypeParser, &parser
  #
  #
  # === Failed JSON parsing
  #
  # Returns "400 Bad request" response if invalid JSON document was sent:
  #
  # Raw HTTP response:
  #
  #   HTTP/1.1 400 Bad Request
  #   Content-Type: text/plain
  #   Content-Length: 28
  #
  #   failed to parse body as JSON
  #
  class PostBodyContentTypeParser

    # Constants
    #
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze

    # Supported Content-Types
    #
    APPLICATION_JSON = 'application/json'.freeze

    def initialize(app, &block)
      warn "[DEPRECATION] `PostBodyContentTypeParser` is deprecated. Use `JSONBodyParser` as a drop-in replacement."
      @app = app
      @block = block || Proc.new { |body| JSON.parse(body, :create_additions => false) }
    end

    def call(env)
      if Rack::Request.new(env).media_type == APPLICATION_JSON && (body = env[POST_BODY].read).length != 0
        env[POST_BODY].rewind if env[POST_BODY].respond_to?(:rewind) # somebody might try to read this stream
        env.update(FORM_HASH => @block.call(body), FORM_INPUT => env[POST_BODY])
      end
      @app.call(env)
    rescue JSON::ParserError
      bad_request('failed to parse body as JSON')
    end

    def bad_request(body = 'Bad Request')
      [ 400, { 'content-type' => 'text/plain', 'content-length' => body.bytesize.to_s }, [body] ]
    end
  end
end
