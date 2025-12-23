require 'logger'

module Geocoder

  def self.log(level, message)
    Logger.instance.log(level, message)
  end

  class Logger
    include Singleton

    SEVERITY = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL
    }

    def log(level, message)
      unless valid_level?(level)
        raise StandardError, "Geocoder tried to log a message with an invalid log level."
      end
      if current_logger.respond_to? :add
        current_logger.add(SEVERITY[level], message)
      else
        raise Geocoder::ConfigurationError, "Please specify valid logger for Geocoder. " +
        "Logger specified must be :kernel or must respond to `add(level, message)`."
      end
      nil
    end

    private # ----------------------------------------------------------------

    def current_logger
      logger = Geocoder.config[:logger]
      if logger == :kernel
        logger = Geocoder::KernelLogger.instance
      end
      logger
    end

    def valid_level?(level)
      SEVERITY.keys.include?(level)
    end
  end
end
