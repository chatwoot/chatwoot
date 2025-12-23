# frozen_string_literal: true

module Faraday
  class Request
    # Middleware for supporting urlencoded requests.
    class UrlEncoded < Faraday::Middleware
      unless defined?(::Faraday::Request::UrlEncoded::CONTENT_TYPE)
        CONTENT_TYPE = 'Content-Type'
      end

      class << self
        attr_accessor :mime_type
      end
      self.mime_type = 'application/x-www-form-urlencoded'

      # Encodes as "application/x-www-form-urlencoded" if not already encoded or
      # of another type.
      #
      # @param env [Faraday::Env]
      def call(env)
        match_content_type(env) do |data|
          params = Faraday::Utils::ParamsHash[data]
          env.body = params.to_query(env.params_encoder)
        end
        @app.call env
      end

      # @param env [Faraday::Env]
      # @yield [request_body] Body of the request
      def match_content_type(env)
        return unless process_request?(env)

        env.request_headers[CONTENT_TYPE] ||= self.class.mime_type
        return if env.body.respond_to?(:to_str) || env.body.respond_to?(:read)

        yield(env.body)
      end

      # @param env [Faraday::Env]
      #
      # @return [Boolean] True if the request has a body and its Content-Type is
      #                   urlencoded.
      def process_request?(env)
        type = request_type(env)
        env.body && (type.empty? || (type == self.class.mime_type))
      end

      # @param env [Faraday::Env]
      #
      # @return [String]
      def request_type(env)
        type = env.request_headers[CONTENT_TYPE].to_s
        type = type.split(';', 2).first if type.index(';')
        type
      end
    end
  end
end

Faraday::Request.register_middleware(url_encoded: Faraday::Request::UrlEncoded)
