# frozen_string_literal: true

require 'logger'

module OpenTelemetry
  module SDK
    # The ForwardingLogger provides a wrapper to control the OpenTelemetry
    # log level, while respecting the configured level of the supplied logger.
    # If the OTEL_LOG_LEVEL is set to debug, and the supplied logger is configured
    # with an ERROR log level, only OpenTelemetry logs at the ERROR level or higher
    # will be emitted.
    class ForwardingLogger
      def initialize(logger, level:)
        @logger = logger

        if level.is_a?(Integer)
          @level = level
        else
          case level.to_s.downcase
          when 'debug'
            @level = Logger::DEBUG
          when 'info'
            @level = Logger::INFO
          when 'warn'
            @level = Logger::WARN
          when 'error'
            @level = Logger::ERROR
          when 'fatal'
            @level = Logger::FATAL
          when 'unknown'
            @level = Logger::UNKNOWN
          else
            raise ArgumentError, "invalid log level: #{level}"
          end
        end
      end

      def add(severity, message = nil, progname = nil, &block)
        return true if severity < @level

        @logger.add(severity, message, progname, &block)
      end

      def debug(progname = nil, &block)
        add(Logger::DEBUG, nil, progname, &block)
      end

      def info(progname = nil, &block)
        add(Logger::INFO, nil, progname, &block)
      end

      def warn(progname = nil, &block)
        add(Logger::WARN, nil, progname, &block)
      end

      def error(progname = nil, &block)
        add(Logger::ERROR, nil, progname, &block)
      end

      def fatal(progname = nil, &block)
        add(Logger::FATAL, nil, progname, &block)
      end

      def unknown(progname = nil, &block)
        add(Logger::UNKNOWN, nil, progname, &block)
      end
    end
  end
end
