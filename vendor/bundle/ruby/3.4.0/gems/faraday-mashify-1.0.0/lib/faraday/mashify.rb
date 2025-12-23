# frozen_string_literal: true

require 'faraday'
require 'hashie/mash'

require_relative 'mashify/middleware'
require_relative 'mashify/version'

module Faraday
  # This will be your middleware main module, though the actual middleware implementation will go
  # into Faraday::Mashify::Middleware for the correct namespacing.
  module Mashify
    # Faraday allows you to register your middleware for easier configuration.
    # This step is totally optional, but it basically allows users to use a
    # custom symbol (in this case, `:mashify`), to use your middleware in their connections.
    # After calling this line, the following are both valid ways to set the middleware in a connection:
    # * conn.use Faraday::Mashify::Middleware
    # * conn.use :mashify
    # Without this line, only the former method is valid.
    # Faraday::Middleware.register_middleware(mashify: Faraday::Mashify::Middleware)

    # Alternatively, you can register your middleware under Faraday::Request or Faraday::Response.
    # This will allow to load your middleware using the `request` or `response` methods respectively.
    #
    # Load middleware with conn.request :mashify
    # Faraday::Request.register_middleware(mashify: Faraday::Mashify::Middleware)
    #
    # Load middleware with conn.response :mashify
    Faraday::Response.register_middleware(mashify: Faraday::Mashify::Middleware)
  end
end
