# frozen_string_literal: true

require "rack"

module Sidekiq
  module WebRouter
    GET = "GET"
    DELETE = "DELETE"
    POST = "POST"
    PUT = "PUT"
    PATCH = "PATCH"
    HEAD = "HEAD"

    ROUTE_PARAMS = "rack.route_params"
    REQUEST_METHOD = "REQUEST_METHOD"
    PATH_INFO = "PATH_INFO"

    def head(path, &block)
      route(HEAD, path, &block)
    end

    def get(path, &block)
      route(GET, path, &block)
    end

    def post(path, &block)
      route(POST, path, &block)
    end

    def put(path, &block)
      route(PUT, path, &block)
    end

    def patch(path, &block)
      route(PATCH, path, &block)
    end

    def delete(path, &block)
      route(DELETE, path, &block)
    end

    def route(method, path, &block)
      @routes ||= {GET => [], POST => [], PUT => [], PATCH => [], DELETE => [], HEAD => []}

      @routes[method] << WebRoute.new(method, path, block)
    end

    def match(env)
      request_method = env[REQUEST_METHOD]
      path_info = ::Rack::Utils.unescape env[PATH_INFO]

      # There are servers which send an empty string when requesting the root.
      # These servers should be ashamed of themselves.
      path_info = "/" if path_info == ""

      @routes[request_method].each do |route|
        params = route.match(request_method, path_info)
        if params
          env[ROUTE_PARAMS] = params

          return WebAction.new(env, route.block)
        end
      end

      nil
    end
  end

  class WebRoute
    attr_accessor :request_method, :pattern, :block, :name

    NAMED_SEGMENTS_PATTERN = /\/([^\/]*):([^.:$\/]+)/

    def initialize(request_method, pattern, block)
      @request_method = request_method
      @pattern = pattern
      @block = block
    end

    def matcher
      @matcher ||= compile
    end

    def compile
      if pattern.match?(NAMED_SEGMENTS_PATTERN)
        p = pattern.gsub(NAMED_SEGMENTS_PATTERN, '/\1(?<\2>[^$/]+)')

        Regexp.new("\\A#{p}\\Z")
      else
        pattern
      end
    end

    def match(request_method, path)
      case matcher
      when String
        {} if path == matcher
      else
        path_match = path.match(matcher)
        path_match&.named_captures&.transform_keys(&:to_sym)
      end
    end
  end
end
