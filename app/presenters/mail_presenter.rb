class MailPresenter < SimpleDelegator
  attr_accessor :mail

  def initialize(mail, account = nil)
    super(mail)
    @mail = mail
    @account = account
  end

  def subject
    encode_to_unicode(@mail.subject)
  end

  # encode decoded mail text_part or html_part if mail is multipart email
  # encode decoded mail raw bodyt if mail is not multipart email but the body content is text/html
  def mail_content(mail_part)
    if multipart_mail_body?
      decoded_multipart_mail(mail_part)
    else
      text_html_mail(mail_part)
    end
  end

  # encodes mail if mail.parts is present
  # encodes mail content type is multipart
  def decoded_multipart_mail(mail_part)
    encoded = encode_to_unicode(mail_part&.decoded)

    encoded if text_mail_body? || html_mail_body?
  end

  # encodes mail raw body if mail.parts is empty
  # encodes mail raw body if mail.content_type is plain/text
  # encodes mail raw body if mail.content_type is html/text
  def text_html_mail(mail_part)
    decoded = mail_part&.decoded || @mail.decoded
    encoded = encode_to_unicode(decoded)

    encoded if html_mail_body? || text_mail_body?
  end

  def text_content
    @decoded_text_content = mail_content(text_part) || ''

    encoding = @decoded_text_content.encoding

    body = EmailReplyTrimmer.trim(@decoded_text_content)

    return {} if @decoded_text_content.blank? || !text_mail_body?

    @text_content ||= {
      full: mail_content(text_part),
      reply: @decoded_text_content,
      quoted: body.force_encoding(encoding).encode('UTF-8')
    }
  end

  def html_content
    encoded = mail_content(html_part) || ''
    @decoded_html_content = ::HtmlParser.parse_reply(encoded)

    return {} if @decoded_html_content.blank? || !html_mail_body?

    body = EmailReplyTrimmer.trim(@decoded_html_content)

    @html_content ||= {
      full: mail_content(html_part),
      reply: @decoded_html_content,
      quoted: body
    }
  end

  # check content disposition check
  # if inline, upload to AWS and and take the URL
  def attachments
    # ref : https://github.com/gorails-screencasts/action-mailbox-action-text/blob/master/app/mailboxes/posts_mailbox.rb
    mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(attachment.body.to_s),
        filename: attachment.filename.presence || "attachment_#{SecureRandom.hex(4)}",
        content_type: attachment.content_type
      )
      { original: attachment, blob: blob }
    end
  end

  def number_of_attachments
    mail.attachments.count
  end

  def serialized_data
    {
      bcc: bcc,
      cc: cc,
      content_type: content_type,
      date: date,
      from: from,
      html_content: html_content,
      in_reply_to: in_reply_to,
      message_id: message_id,
      multipart: multipart?,
      number_of_attachments: number_of_attachments,
      subject: subject,
      text_content: text_content,
      to: to
    }
  end

  def in_reply_to
    return if @mail.in_reply_to.blank?

    # Although the "in_reply_to" field in the email can potentially hold multiple values,
    # our current system does not have the capability to handle this.
    # FIX ME: Address this issue by returning the complete results and utilizing them for querying conversations.
    @mail.in_reply_to.is_a?(Array) ? @mail.in_reply_to.first : @mail.in_reply_to
  end

  def from
    # changing to downcase to avoid case mismatch while finding contact
    (@mail.reply_to.presence || @mail.from).map(&:downcase)
  end

  def sender_name
    Mail::Address.new((@mail[:reply_to] || @mail[:from]).value).name
  end

  def original_sender
    from_email_address(@mail[:reply_to].try(:value)) || @mail['X-Original-Sender'].try(:value) || from_email_address(from.first)
  end

  def from_email_address(email)
    Mail::Address.new(email).address
  end

  def email_forwarded_for
    @mail['X-Forwarded-For'].try(:value)
  end

  def mail_receiver
    if @mail.to.blank?
      return [email_forwarded_for] if email_forwarded_for.present?

      []
    else
      @mail.to
    end
  end

  def auto_reply?
    auto_submitted? || x_auto_reply?
  end

  def notification_email_from_chatwoot?
    # notification emails are send via mailer sender email address. so it should match
    original_sender == Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')).address
  end

  private

  def auto_submitted?
    @mail['Auto-Submitted'].present? && @mail['Auto-Submitted'].value != 'no'
  end

  def x_auto_reply?
    @mail['X-Autoreply'].present? && @mail['X-Autoreply'].value == 'yes'
  end

  # forcing the encoding of the content to UTF-8 so as to be compatible with database and serializers
  def encode_to_unicode(str)
    return '' if str.blank?

    current_encoding = str.encoding.name
    return str if current_encoding == 'UTF-8'

    str.encode(current_encoding, 'UTF-8', invalid: :replace, undef: :replace, replace: '?')
  rescue StandardError
    ''
  end

  def html_mail_body?
    ((mail.content_type || '').include? 'text/html') || @mail.html_part&.content_type&.include?('text/html')
  end

  def text_mail_body?
    ((mail.content_type || '').include? 'text/plain') || @mail.text_part&.content_type&.include?('text/plain')
  end

  def multipart_mail_body?
    ((mail.content_type || '').include? 'multipart') || @mail.parts.any?
  end
end
