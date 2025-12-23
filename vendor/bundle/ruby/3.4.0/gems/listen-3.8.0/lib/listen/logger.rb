# frozen_string_literal: true

module Listen
  @logger = nil

  # Listen.logger will always be present.
  # If you don't want logging, set Listen.logger = ::Logger.new('/dev/null', level: ::Logger::UNKNOWN)

  class << self
    attr_writer :logger

    def logger
      @logger ||= default_logger
    end

    private

    def default_logger
      level =
        case ENV['LISTEN_GEM_DEBUGGING'].to_s
        when /debug|2/i
          ::Logger::DEBUG
        when /info|true|yes|1/i
          ::Logger::INFO
        when /warn/i
          ::Logger::WARN
        when /fatal/i
          ::Logger::FATAL
        else
          ::Logger::ERROR
        end

      ::Logger.new(STDERR, level: level)
    end
  end
end
