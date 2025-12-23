# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware/request/aws_sigv4'

module FaradayMiddleware
  Faraday::Request.register_middleware aws_sigv4: FaradayMiddleware::AwsSigV4
end
