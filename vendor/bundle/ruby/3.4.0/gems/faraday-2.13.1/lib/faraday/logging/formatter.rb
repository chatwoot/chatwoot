# frozen_string_literal: true

require 'pp' # This require is necessary for Hash#pretty_inspect to work, do not remove it, people rely on it.

module Faraday
  module Logging
    # Serves as an integration point to customize logging
    class Formatter
      extend Forwardable

      DEFAULT_OPTIONS = { headers: true, bodies: false, errors: false,
                          log_level: :info }.freeze

      def initialize(logger:, options:)
        @logger = logger
        @options = DEFAULT_OPTIONS.merge(options)
        unless %i[debug info warn error fatal].include?(@options[:log_level])
          @options[:log_level] = :info
        end
        @filter = []
      end

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      def request(env)
        public_send(log_level) do
          "request: #{env.method.upcase} #{apply_filters(env.url.to_s)}"
        end

        log_headers('request', env.request_headers) if log_headers?(:request)
        log_body('request', env[:body]) if env[:body] && log_body?(:request)
      end

      def response(env)
        public_send(log_level) { "response: Status #{env.status}" }

        log_headers('response', env.response_headers) if log_headers?(:response)
        log_body('response', env[:body]) if env[:body] && log_body?(:response)
      end

      def exception(exc)
        return unless log_errors?

        public_send(log_level) { "error: #{exc.full_message}" }

        log_headers('error', exc.response_headers) if exc.respond_to?(:response_headers) && log_headers?(:error)
        return unless exc.respond_to?(:response_body) && exc.response_body && log_body?(:error)

        log_body('error', exc.response_body)
      end

      def filter(filter_word, filter_replacement)
        @filter.push([filter_word, filter_replacement])
      end

      private

      def dump_headers(headers)
        return if headers.nil?

        headers.map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
      end

      def dump_body(body)
        if body.respond_to?(:to_str)
          body.to_str
        else
          pretty_inspect(body)
        end
      end

      def pretty_inspect(body)
        body.pretty_inspect
      end

      def log_headers?(type)
        case @options[:headers]
        when Hash
          @options[:headers][type]
        else
          @options[:headers]
        end
      end

      def log_body?(type)
        case @options[:bodies]
        when Hash
          @options[:bodies][type]
        else
          @options[:bodies]
        end
      end

      def log_errors?
        @options[:errors]
      end

      def apply_filters(output)
        @filter.each do |pattern, replacement|
          output = output.to_s.gsub(pattern, replacement)
        end
        output
      end

      def log_level
        @options[:log_level]
      end

      def log_headers(type, headers)
        public_send(log_level) { "#{type}: #{apply_filters(dump_headers(headers))}" }
      end

      def log_body(type, body)
        public_send(log_level) { "#{type}: #{apply_filters(dump_body(body))}" }
      end
    end
  end
end
