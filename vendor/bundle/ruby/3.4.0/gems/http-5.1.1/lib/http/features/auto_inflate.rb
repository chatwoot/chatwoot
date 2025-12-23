# frozen_string_literal: true

require "set"

module HTTP
  module Features
    class AutoInflate < Feature
      SUPPORTED_ENCODING = Set.new(%w[deflate gzip x-gzip]).freeze
      private_constant :SUPPORTED_ENCODING

      def wrap_response(response)
        return response unless supported_encoding?(response)

        options = {
          :status        => response.status,
          :version       => response.version,
          :headers       => response.headers,
          :proxy_headers => response.proxy_headers,
          :connection    => response.connection,
          :body          => stream_for(response.connection),
          :request       => response.request
        }

        Response.new(options)
      end

      def stream_for(connection)
        Response::Body.new(Response::Inflater.new(connection))
      end

      private

      def supported_encoding?(response)
        content_encoding = response.headers.get(Headers::CONTENT_ENCODING).first
        content_encoding && SUPPORTED_ENCODING.include?(content_encoding)
      end

      HTTP::Options.register_feature(:auto_inflate, self)
    end
  end
end
