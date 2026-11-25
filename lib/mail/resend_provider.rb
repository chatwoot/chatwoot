module Mail # rubocop:disable Style/ClassAndModuleChildren
  class ResendProvider
    class DeliveryError < StandardError; end

    # Resend builds the MIME message itself, so the headers it would otherwise drop are passed
    # through: without them a reply does not thread under the customer's mail.
    THREADING_HEADERS = %w[Message-ID In-Reply-To References].freeze

    # Mail::Message#deliver! reads `settings[:return_response]` after delivering, so a delivery
    # method without it raises with the email already sent.
    attr_accessor :settings

    def initialize(settings)
      @settings = settings
    end

    def deliver!(mail)
      Resend::Emails.send(payload(mail))
    rescue Resend::Error => e
      raise DeliveryError, "Failed to send email: #{e.message}"
    rescue StandardError => e
      raise DeliveryError, "An error occurred while sending email: #{e.message}"
    end

    private

    def payload(mail)
      {
        from: mail.header[:from].to_s,
        to: mail.header[:to].to_s,
        cc: addresses(mail, :cc),
        bcc: addresses(mail, :bcc),
        reply_to: addresses(mail, :reply_to),
        subject: mail.header[:subject].to_s,
        **bodies(mail),
        headers: threading_headers(mail).presence,
        attachments: mail.attachments.map { |attachment| attachment_payload(attachment) }.presence
      }.compact
    end

    # A message with an attachment is multipart, and `Mail::Message#decoded` raises on those.
    def bodies(mail)
      html = mail.multipart? ? mail.html_part&.decoded : mail.decoded
      { html: html, text: mail.text_part&.decoded || sanitize_html(html.to_s) }
    end

    # An address the Mail gem cannot parse (the `reply+<uuid>@` an install with no inbound domain
    # builds) is kept as an unstructured field. SMTP writes it out verbatim and the reply still
    # goes; Resend would refuse the whole email over it, so it is left out instead.
    def addresses(mail, name)
      field = mail[name]&.field
      field.formatted.presence if field.respond_to?(:formatted)
    end

    def threading_headers(mail)
      THREADING_HEADERS.filter_map { |name| [name, mail.header[name].value] if mail.header[name] }.to_h
    end

    def attachment_payload(attachment)
      {
        filename: attachment.filename,
        # The file's own bytes: `decoded` on a text part converts it to the part's charset.
        content: Base64.strict_encode64(attachment.body.decoded),
        content_type: attachment.mime_type,
        content_id: (attachment.content_id.delete('<>') if attachment.inline?)
      }.compact
    end

    def sanitize_html(html)
      sanitized = ActionView::Base.full_sanitizer.sanitize(html)
      # NOTE: Remove more than two consecutive newlines
      sanitized.lines.map(&:strip).join("\n").gsub(/\n{3,}/, "\n\n").strip
    end
  end
end
