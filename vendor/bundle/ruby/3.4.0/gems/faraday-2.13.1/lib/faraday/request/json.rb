# frozen_string_literal: true

require 'json'

module Faraday
  class Request
    # Request middleware that encodes the body as JSON.
    #
    # Processes only requests with matching Content-type or those without a type.
    # If a request doesn't have a type but has a body, it sets the Content-type
    # to JSON MIME-type.
    #
    # Doesn't try to encode bodies that already are in string form.
    class Json < Middleware
      MIME_TYPE = 'application/json'
      MIME_TYPE_REGEX = %r{^application/(vnd\..+\+)?json$}

      def on_request(env)
        match_content_type(env) do |data|
          env[:body] = encode(data)
        end
      end

      private

      def encode(data)
        if options[:encoder].is_a?(Array) && options[:encoder].size >= 2
          options[:encoder][0].public_send(options[:encoder][1], data)
        elsif options[:encoder].respond_to?(:dump)
          options[:encoder].dump(data)
        else
          ::JSON.generate(data)
        end
      end

      def match_content_type(env)
        return unless process_request?(env)

        env[:request_headers][CONTENT_TYPE] ||= MIME_TYPE
        yield env[:body] unless env[:body].respond_to?(:to_str)
      end

      def process_request?(env)
        type = request_type(env)
        body?(env) && (type.empty? || type.match?(MIME_TYPE_REGEX))
      end

      def body?(env)
        body = env[:body]
        case body
        when true, false
          true
        when nil
          # NOTE: nil can be converted to `"null"`, but this middleware doesn't process `nil` for the compatibility.
          false
        else
          !(body.respond_to?(:to_str) && body.empty?)
        end
      end

      def request_type(env)
        type = env[:request_headers][CONTENT_TYPE].to_s
        type = type.split(';', 2).first if type.index(';')
        type
      end
    end
  end
end

Faraday::Request.register_middleware(json: Faraday::Request::Json)
