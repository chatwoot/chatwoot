# frozen_string_literal: true

require 'rack/protection'

module Rack
  module Protection
    ##
    # Prevented attack::   CSRF
    # Supported browsers:: Google Chrome 2, Safari 4 and later
    # More infos::         http://en.wikipedia.org/wiki/Cross-site_request_forgery
    #                      http://tools.ietf.org/html/draft-abarth-origin
    #
    # Does not accept unsafe HTTP requests when value of Origin HTTP request header
    # does not match default or permitted URIs.
    #
    # If you want to permit a specific domain, you can pass in as the `:permitted_origins` option:
    #
    #     use Rack::Protection, permitted_origins: ["http://localhost:3000", "http://127.0.01:3000"]
    #
    # The `:allow_if` option can also be set to a proc to use custom allow/deny logic.
    class HttpOrigin < Base
      DEFAULT_PORTS = { 'http' => 80, 'https' => 443, 'coffee' => 80 }
      default_reaction :deny
      default_options allow_if: nil

      def base_url(env)
        request = Rack::Request.new(env)
        port = ":#{request.port}" unless request.port == DEFAULT_PORTS[request.scheme]
        "#{request.scheme}://#{request.host}#{port}"
      end

      def accepts?(env)
        return true if safe? env
        return true unless (origin = env['HTTP_ORIGIN'])
        return true if base_url(env) == origin
        return true if options[:allow_if]&.call(env)

        permitted_origins = options[:permitted_origins]
        Array(permitted_origins).include? origin
      end
    end
  end
end
