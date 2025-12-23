# frozen_string_literal: true

require 'rack/protection'

module Rack
  module Protection
    ##
    # Prevented attack::   Secret leakage, third party tracking
    # Supported browsers:: mixed support
    # More infos::         https://www.w3.org/TR/referrer-policy/
    #                      https://caniuse.com/#search=referrer-policy
    #
    # Sets Referrer-Policy header to tell the browser to limit the Referer header.
    #
    # Options:
    # referrer_policy:: The policy to use (default: 'strict-origin-when-cross-origin')
    class ReferrerPolicy < Base
      default_options referrer_policy: 'strict-origin-when-cross-origin'

      def call(env)
        status, headers, body = @app.call(env)
        headers['referrer-policy'] ||= options[:referrer_policy]
        [status, headers, body]
      end
    end
  end
end
