# frozen_string_literal: true

module HTTP
  module Features
    # Log requests and responses. Request verb and uri, and Response status are
    # logged at `info`, and the headers and bodies of both are logged at
    # `debug`. Be sure to specify the logger when enabling the feature:
    #
    #    HTTP.use(logging: {logger: Logger.new(STDOUT)}).get("https://example.com/")
    #
    class Logging < Feature
      HTTP::Options.register_feature(:logging, self)

      class NullLogger
        %w[fatal error warn info debug].each do |level|
          define_method(level.to_sym) do |*_args|
            nil
          end

          define_method(:"#{level}?") do
            true
          end
        end
      end

      attr_reader :logger

      def initialize(logger: NullLogger.new)
        @logger = logger
      end

      def wrap_request(request)
        logger.info { "> #{request.verb.to_s.upcase} #{request.uri}" }
        logger.debug { "#{stringify_headers(request.headers)}\n\n#{request.body.source}" }

        request
      end

      def wrap_response(response)
        logger.info { "< #{response.status}" }
        logger.debug { "#{stringify_headers(response.headers)}\n\n#{response.body}" }

        response
      end

      private

      def stringify_headers(headers)
        headers.map { |name, value| "#{name}: #{value}" }.join("\n")
      end
    end
  end
end
