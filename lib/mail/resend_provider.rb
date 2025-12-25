module Mail # rubocop:disable Style/ClassAndModuleChildren
  class ResendProvider
    class DeliveryError < StandardError; end

    attr_accessor :settings

    def initialize(values)
      @settings = values
    end

    def deliver!(mail)
      Resend::Emails.send(
        from: mail.smtp_envelope_from,
        to: mail.smtp_envelope_to,
        subject: mail.subject,
        html: mail.decoded,
        text: sanitize_html(mail.decoded)
      )
    rescue Resend::Error => e
      raise DeliveryError, "Failed to send email: #{e.message}"
    rescue StandardError => e
      raise DeliveryError, "An error occurred while sending email: #{e.message}"
    end

    private

    def sanitize_html(html)
      sanitized = ActionView::Base.full_sanitizer.sanitize(html)
      # NOTE: Remove more than two consecutive newlines
      sanitized.lines.map(&:strip).join("\n").gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
