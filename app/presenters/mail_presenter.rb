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

  def text_content
    @decoded_text_content = select_body(text_part) || ''
    encoding = @decoded_text_content.encoding

    body = EmailReplyTrimmer.trim(@decoded_text_content)

    return {} if @decoded_text_content.blank?

    @text_content ||= {
      full: select_body(text_part),
      reply: @decoded_text_content,
      quoted: body.force_encoding(encoding).encode('UTF-8')
    }
  end

  # returns encoded mail body text_part if available.
  # returns encoded mail body as it is if mail_part not available.
  # else returns parsed the html body if contains text/html content.
  def select_body(mail_part)
    return encoded_mail_body unless mail_part

    decoded = encode_to_unicode(mail_part.decoded)

    if mail.text_part
      decoded
    elsif html_mail_body?
      ::HtmlParser.parse_reply(decoded)
    end
  end

  def html_content
    @decoded_html_content = select_body(html_part) || ''

    return {} if @decoded_html_content.blank?

    body = EmailReplyTrimmer.trim(@decoded_html_content)

    @html_content ||= {
      full: select_body(html_part),
      reply: @decoded_html_content,
      quoted: body
    }
  end

  def attachments
    # ref : https://github.com/gorails-screencasts/action-mailbox-action-text/blob/master/app/mailboxes/posts_mailbox.rb
    mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(attachment.body.to_s),
        filename: attachment.filename,
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

  def from
    # changing to downcase to avoid case mismatch while finding contact
    (@mail.reply_to.presence || @mail.from).map(&:downcase)
  end

  def sender_name
    Mail::Address.new((@mail[:reply_to] || @mail[:from]).value).name
  end

  def original_sender
    @mail[:reply_to].try(:value) || @mail['X-Original-Sender'].try(:value) || from.first
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

  private

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
    ((mail.content_type || '').include? 'text/html') || @mail.html_part || @mail.html_part.content_type.include?('text/html')
  end

  # returns mail body if mail content_type is text/plain
  def encoded_mail_body
    return encode_to_unicode(@mail.body.decoded) if (@mail.content_type || '').include? 'text/plain'

    ''
  end
end
