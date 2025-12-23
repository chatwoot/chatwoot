# frozen_string_literal: true
#
# This whole class and associated specs is deprecated and will go away in the version 3 release of mail.
module Mail
  module CheckDeliveryParams #:nodoc:
    class << self

      extend Gem::Deprecate

      def check(mail)
        envelope = Mail::SmtpEnvelope.new(mail)
        [ envelope.from,
          envelope.to,
          envelope.message ]
      end
      deprecate :check, 'Mail::SmtpEnvelope.new created in commit c106bebea066782a72e4f24dd37b532d95773df7', 2023, 6

      def check_from(addr)
        mail = Mail.new(from: 'deprecated@example.com', to: 'deprecated@example.com')
        Mail::SmtpEnvelope.new(mail).send(:validate_addr, 'From', addr)
      end
      deprecate :check_from, :none, 2023, 6

      def check_to(addrs)
        mail = Mail.new(from: 'deprecated@example.com', to: 'deprecated@example.com')
        Array(addrs).map do |addr|
          Mail::SmtpEnvelope.new(mail).send(:validate_addr, 'To', addr)
        end
      end
      deprecate :check_to, :none, 2023, 6

      def check_addr(addr_name, addr)
        mail = Mail.new(from: 'deprecated@example.com', to: 'deprecated@example.com')
        Mail::SmtpEnvelope.new(mail).send(:validate_addr, addr_name, addr)
      end
      deprecate :check_addr, :none, 2023, 6

      def validate_smtp_addr(addr)
        if addr
          if addr.bytesize > 2048
            yield 'may not exceed 2kB'
          end

          if /[\r\n]/ =~ addr
            yield 'may not contain CR or LF line breaks'
          end
        end

        addr
      end
      deprecate :validate_smtp_addr, :none, 2023, 6

      def check_message(message)
        message = message.encoded if message.respond_to?(:encoded)

        if Utilities.blank?(message)
          raise ArgumentError, 'An encoded message is required to send an email'
        end

        message
      end
      deprecate :check_message, :none, 2023, 6
    end
  end
end
