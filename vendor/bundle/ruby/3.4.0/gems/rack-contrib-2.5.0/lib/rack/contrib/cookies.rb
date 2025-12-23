# frozen_string_literal: true

module Rack
  class Cookies
    class CookieJar < Hash
      def initialize(cookies)
        @set_cookies = {}
        @delete_cookies = {}
        super()
        update(cookies)
      end

      def [](name)
        super(name.to_s)
      end

      def []=(key, options)
        unless options.is_a?(Hash)
          options = { :value => options }
        end

        options[:path] ||= '/'
        @set_cookies[key] = options
        super(key.to_s, options[:value])
      end

      def delete(key, options = {})
        options[:path] ||= '/'
        @delete_cookies[key] = options
        super(key.to_s)
      end

      def finish!(resp)
        @set_cookies.each { |k, v| resp.set_cookie(k, v) }
        @delete_cookies.each { |k, v| resp.delete_cookie(k, v) }
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Request.new(env)
      env['rack.cookies'] = cookies = CookieJar.new(req.cookies)
      status, headers, body = @app.call(env)
      resp = Response.new(body, status, headers)
      cookies.finish!(resp)
      resp.to_a
    end
  end
end
