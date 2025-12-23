require 'mail/smtp_envelope'

module Mail
  class LoggerDelivery
    attr_reader :logger, :severity, :settings

    def initialize(settings)
      @settings = settings
      @logger   = settings.fetch(:logger) { default_logger }
      @severity = derive_severity(settings[:severity])
    end

    def deliver!(mail)
      logger.log(severity) { Mail::SmtpEnvelope.new(mail).message }
    end

    private
      def default_logger
        require 'logger'
        ::Logger.new($stdout)
      end

      def derive_severity(severity)
        case severity
        when nil
          Logger::INFO
        when Integer
          severity
        else
          Logger.const_get(severity.to_s.upcase)
        end
      end
  end
end
