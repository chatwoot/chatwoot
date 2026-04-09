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
      headers: headers_data,
      html_content: html_content,
      in_reply_to: in_reply_to,
      message_id: message_id,
      multipart: multipart?,
      number_of_attachments: number_of_attachments,
      references: references,
      subject: subject,
      text_content: text_content,
      to: to,
      auto_reply: auto_reply?
    }
  end

  def in_reply_to
    return if @mail.in_reply_to.blank?

    # Although the "in_reply_to" field in the email can potentially hold multiple values,
    # our current system does not have the capability to handle this.
    # FIX ME: Address this issue by returning the complete results and utilizing them for querying conversations.
    @mail.in_reply_to.is_a?(Array) ? @mail.in_reply_to.first : @mail.in_reply_to
  end

  def references
    return [] if @mail.references.blank?

    Array.wrap(@mail.references)
  end

  def from
    # changing to downcase to avoid case mismatch while finding contact
    Array.wrap(@mail.reply_to.presence || @mail.from).map(&:downcase)
  end

  def sender_name
    parse_mail_address((@mail[:reply_to] || @mail[:from]).value)&.name
  end

  def original_sender
    [
      @mail[:reply_to]&.value,
      @mail['X-Original-Sender']&.value,
      @mail[:from]&.value
    ].filter_map { |email| parse_mail_address(email)&.address }.first
  end

  def headers_data
    headers = {
      'x-original-from' => @mail['X-Original-From']&.value,
      'x-original-sender' => @mail['X-Original-Sender']&.value,
      'x-forwarded-for' => @mail['X-Forwarded-For']&.value
    }.compact

    headers.presence
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

  def bounced?
    @mail.bounced? || @mail['X-Failed-Recipients'].try(:value).present?
  end

  def notification_email_from_chatwoot?
    # notification emails are send via mailer sender email address. so it should match
    configured_sender = Mail::Address.new(ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')).address
    original_sender.to_s.casecmp?(configured_sender)
  end

  private

  def parse_mail_address(email)
    return if email.blank?

    Mail::Address.new(email)
  rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
    nil
  end

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
