# frozen_string_literal: true

module Mail
  class SmtpEnvelope #:nodoc:
    # Reasonable cap on address length to avoid SMTP line length
    # overflow on old SMTP servers.
    MAX_ADDRESS_BYTESIZE = 2000

    attr_reader :from, :to, :message

    def initialize(mail)
      self.from = mail.smtp_envelope_from
      self.to = mail.smtp_envelope_to
      self.message = mail.encoded
    end

    def from=(addr)
      if Utilities.blank? addr
        raise ArgumentError, "SMTP From address may not be blank: #{addr.inspect}"
      end

      @from = validate_addr 'From', addr
    end

    def to=(addr)
      if Utilities.blank?(addr)
        raise ArgumentError, "SMTP To address may not be blank: #{addr.inspect}"
      end

      @to = Array(addr).map do |addr|
        validate_addr 'To', addr
      end
    end

    def message=(message)
      if Utilities.blank?(message)
        raise ArgumentError, 'SMTP message may not be blank'
      end

      @message = message
    end


    private
      def validate_addr(addr_name, addr)
        if addr.bytesize > MAX_ADDRESS_BYTESIZE
          raise ArgumentError, "SMTP #{addr_name} address may not exceed #{MAX_ADDRESS_BYTESIZE} bytes: #{addr.inspect}"
        end

        if /[\r\n]/ =~ addr
          raise ArgumentError, "SMTP #{addr_name} address may not contain CR or LF line breaks: #{addr.inspect}"
        end

        addr
      end
  end
end
