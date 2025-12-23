# frozen_string_literal: true

require 'rack/utils'

module Rack
  # Rack middleware for parsing POST/PUT body data into nested parameters
  class NestedParams

    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    POST_BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze
    FORM_VARS = 'rack.request.form_vars'.freeze

    # supported content type
    URL_ENCODED = 'application/x-www-form-urlencoded'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      if form_vars = env[FORM_VARS]
        Rack::Utils.parse_nested_query(form_vars)
      elsif env[CONTENT_TYPE] == URL_ENCODED
        post_body = env[POST_BODY]
        env[FORM_INPUT] = post_body
        env[FORM_HASH] = Rack::Utils.parse_nested_query(post_body.read)
        post_body.rewind
      end
      @app.call(env)
    end
  end
end
