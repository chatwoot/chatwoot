# frozen_string_literal: true

require 'faraday'
require_relative 'retriable_response'
require_relative 'retry/middleware'
require_relative 'retry/version'

module Faraday
  # Middleware main module.
  module Retry
    Faraday::Request.register_middleware(retry: Faraday::Retry::Middleware)
  end
end
