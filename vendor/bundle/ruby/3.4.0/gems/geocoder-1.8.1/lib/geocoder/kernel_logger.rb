module Geocoder
  class KernelLogger
    include Singleton

    def add(level, message)
      return unless log_message_at_level?(level)
      case level
        when ::Logger::DEBUG, ::Logger::INFO
          puts message
        when ::Logger::WARN
          warn message
        when ::Logger::ERROR
          raise message
        when ::Logger::FATAL
          fail message
      end
    end

    private # ----------------------------------------------------------------

    def log_message_at_level?(level)
      level >= Geocoder.config.kernel_logger_level
    end
  end
end
