# frozen_string_literal: true

module TestProf
  # Helper for output printing
  module Logging
    COLORS = {
      INFO: "\e[34m", # blue
      WARN: "\e[33m", # yellow
      ERROR: "\e[31m" # red
    }.freeze

    class Formatter
      def call(severity, _time, progname, msg)
        colorize(severity.to_sym, "[#{progname} #{severity}] #{msg}") + "\n"
      end

      private

      def colorize(level, msg)
        return msg unless TestProf.config.color?

        return msg unless COLORS.key?(level)

        "#{COLORS[level]}#{msg}\e[0m"
      end
    end

    def log(level, msg)
      TestProf.config.logger.public_send(level, "TEST PROF") { msg }
    end
  end
end
