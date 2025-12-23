# frozen_string_literal: true

class UniformNotifier
  class CustomizedLogger < Base
    class << self
      @logger = nil

      def active?
        @logger
      end

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")
        @logger.warn message
      end

      def setup(logdev)
        require 'logger'

        @logger = Logger.new(logdev)

        def @logger.format_message(severity, timestamp, _progname, msg)
          "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')}[#{severity}] #{msg}"
        end
      end
    end
  end
end
