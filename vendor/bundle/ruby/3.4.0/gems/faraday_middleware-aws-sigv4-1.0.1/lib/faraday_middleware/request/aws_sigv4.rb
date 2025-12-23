# frozen_string_literal: true

require 'aws-sigv4'
require 'faraday_middleware/request/aws_sigv4_util'

module FaradayMiddleware
  class AwsSigV4 < Faraday::Middleware
    include FaradayMiddleware::AwsSigV4Util

    def initialize(app, options = nil)
      super(app)
      @signer = Aws::Sigv4::Signer.new(options)
      @options = options
    end

    def call(env)
      sign!(env)
      @app.call(env)
    end

    private

    def sign!(env)
      request = build_aws_sigv4_request(env)
      signature = @signer.sign_request(request)

      signature.headers.each do |name, value|
        env.request_headers[name] = value
      end
    end

    def build_aws_sigv4_request(env)
      {
        http_method: env.method.to_s,
        url: seahorse_encode_query(env.url),
        headers: env.request_headers,
        body: env.body
      }
    end
  end
end
