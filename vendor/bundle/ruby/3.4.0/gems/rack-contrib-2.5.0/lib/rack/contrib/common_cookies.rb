# frozen_string_literal: true

module Rack
  # Rack middleware to use common cookies across domain and subdomains.
  class CommonCookies
    DOMAIN_REGEXP = /([^.]*)\.([^.]*|..\...|...\...|..\....)$/
    LOCALHOST_OR_IP_REGEXP = /^([\d.]+|localhost)$/
    PORT = /:\d+$/

    HEADERS_KLASS = Rack.release < "3" ? Utils::HeaderHash : Headers
    private_constant :HEADERS_KLASS

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = HEADERS_KLASS.new.merge(headers)

      host = env['HTTP_HOST'].sub PORT, ''
      share_cookie(headers, host)

      [status, headers, body]
    end

    private

    def domain(host)
      host =~ DOMAIN_REGEXP
      ".#{$1}.#{$2}"
    end

    def share_cookie(headers, host)
      headers['Set-Cookie'] &&= common_cookie(headers, host) if host !~ LOCALHOST_OR_IP_REGEXP
    end

    def cookie(headers)
      cookies = headers['Set-Cookie']
      cookies.is_a?(Array) ? cookies.join("\n") : cookies
    end

    def common_cookie(headers, host)
      cookie(headers).gsub(/; domain=[^;]*/, '').gsub(/$/, "; domain=#{domain(host)}")
    end
  end
end
