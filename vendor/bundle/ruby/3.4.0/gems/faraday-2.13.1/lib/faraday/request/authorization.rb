# frozen_string_literal: true

module Faraday
  class Request
    # Request middleware for the Authorization HTTP header
    class Authorization < Faraday::Middleware
      KEY = 'Authorization'

      # @param app [#call]
      # @param type [String, Symbol] Type of Authorization
      # @param params [Array<String, Proc, #call>] parameters to build the Authorization header.
      #   If the type is `:basic`, then these can be a login and password pair.
      #   Otherwise, a single value is expected that will be appended after the type.
      #   This value can be a proc or an object responding to `.call`, in which case
      #   it will be invoked on each request.
      def initialize(app, type, *params)
        @type = type
        @params = params
        super(app)
      end

      # @param env [Faraday::Env]
      def on_request(env)
        return if env.request_headers[KEY]

        env.request_headers[KEY] = header_from(@type, env, *@params)
      end

      private

      # @param type [String, Symbol]
      # @param env [Faraday::Env]
      # @param params [Array]
      # @return [String] a header value
      def header_from(type, env, *params)
        if type.to_s.casecmp('basic').zero? && params.size == 2
          Utils.basic_header_from(*params)
        elsif params.size != 1
          raise ArgumentError, "Unexpected params received (got #{params.size} instead of 1)"
        else
          value = params.first
          if (value.is_a?(Proc) && value.arity == 1) || (value.respond_to?(:call) && value.method(:call).arity == 1)
            value = value.call(env)
          elsif value.is_a?(Proc) || value.respond_to?(:call)
            value = value.call
          end
          "#{type} #{value}"
        end
      end
    end
  end
end

Faraday::Request.register_middleware(authorization: Faraday::Request::Authorization)
