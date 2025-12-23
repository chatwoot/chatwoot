# frozen_string_literal: true

require 'csshttprequest'

module Rack

  # A Rack middleware for providing CSSHTTPRequest responses.
  class CSSHTTPRequest
    HEADERS_KLASS = Rack.release < "3" ? Utils::HeaderHash : Headers
    private_constant :HEADERS_KLASS

    def initialize(app)
      @app = app
    end

    # Proxies the request to the application then encodes the response with
    # the CSSHTTPRequest encoder
    def call(env)
      status, headers, response = @app.call(env)
      headers = HEADERS_KLASS.new.merge(headers)

      if chr_request?(env)
        encoded_response = encode(response)
        modify_headers!(headers, encoded_response)
        response = [encoded_response]
      end
      [status, headers, response]
    end

    def chr_request?(env)
      env['csshttprequest.chr'] ||=
        !(/\.chr$/.match(env['PATH_INFO'])).nil? || Rack::Request.new(env).params['_format'] == 'chr'
    end

    def encode(body)
      ::CSSHTTPRequest.encode(body.to_enum.to_a.join)
    end

    def modify_headers!(headers, encoded_response)
      headers['Content-Length'] = encoded_response.bytesize.to_s
      headers['Content-Type'] = 'text/css'
      nil
    end
  end
end
