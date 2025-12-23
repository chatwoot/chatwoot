# frozen_string_literal: true

module HTTParty
  module Logger
    class LogstashFormatter #:nodoc:
      TAG_NAME = HTTParty.name

      attr_accessor :level, :logger

      def initialize(logger, level)
        @logger = logger
        @level  = level.to_sym
      end

      def format(request, response)
        @request = request
        @response = response

        logger.public_send level, logstash_message
      end

      private

      attr_reader :request, :response

      def logstash_message
        {
          '@timestamp' => current_time,
          '@version' => 1,
          'content_length' => content_length || '-',
          'http_method' => http_method,
          'message' => message,
          'path' => path,
          'response_code' => response.code,
          'severity' => level,
          'tags' => [TAG_NAME],
        }.to_json
      end

      def message
        "[#{TAG_NAME}] #{response.code} \"#{http_method} #{path}\" #{content_length || '-'} "
      end

      def current_time
        Time.now.strftime('%Y-%m-%d %H:%M:%S %z')
      end

      def http_method
        @http_method ||= request.http_method.name.split('::').last.upcase
      end

      def path
        @path ||= request.path.to_s
      end

      def content_length
        @content_length ||= response.respond_to?(:headers) ? response.headers['Content-Length'] : response['Content-Length']
      end
    end
  end
end
