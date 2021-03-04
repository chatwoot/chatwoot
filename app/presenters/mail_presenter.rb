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
    @decoded_text_content ||= encode_to_unicode(text_part&.decoded || fallback_content)
    @text_content ||= {
      full: @decoded_text_content,
      reply: extract_reply(@decoded_text_content)[:reply],
      quoted: extract_reply(@decoded_text_content)[:quoted_text]
    }
  end

  def html_content
    @decoded_html_content ||= encode_to_unicode(html_part&.decoded || fallback_content)
    @html_content ||= {
      full: @decoded_html_content,
      reply: extract_reply(@decoded_html_content)[:reply],
      quoted: extract_reply(@decoded_html_content)[:quoted_text]
    }
  end

  def fallback_content
    body&.decoded || ''
  end

  def attachments
    # ref : https://github.com/gorails-screencasts/action-mailbox-action-text/blob/master/app/mailboxes/posts_mailbox.rb
    mail.attachments.map do |attachment|
      blob = ActiveStorage::Blob.create_after_upload!(
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
      text_content: text_content,
      html_content: html_content,
      number_of_attachments: number_of_attachments,
      subject: subject,
      date: date,
      to: to,
      from: from,
      in_reply_to: in_reply_to,
      cc: cc,
      bcc: bcc,
      message_id: message_id
    }
  end

  private

  # forcing the encoding of the content to UTF-8 so as to be compatible with database and serializers
  def encode_to_unicode(str)
    current_encoding = str.encoding.name
    return str if current_encoding == 'UTF-8'

    str.encode(current_encoding, 'UTF-8', invalid: :replace, undef: :replace, replace: '?')
  end

  def extract_reply(content)
    @regex_arr ||= quoted_text_regexes

    content_length = content.length
    # calculates the matching regex closest to top of page
    index = @regex_arr.inject(content_length) do |min, regex|
      [(content.index(regex) || content_length), min].min
    end

    {
      reply: content[0..(index - 1)].strip,
      quoted_text: content[index..].strip
    }
  end

  def quoted_text_regexes
    return sender_agnostic_regexes if @account.nil? || @account.support_email.blank?

    [
      Regexp.new("From:\s* #{Regexp.escape(@account.support_email)}", Regexp::IGNORECASE),
      Regexp.new("<#{Regexp.escape(@account.support_email)}>", Regexp::IGNORECASE),
      Regexp.new("#{Regexp.escape(@account.support_email)}\s+wrote:", Regexp::IGNORECASE),
      Regexp.new("On(.*)#{Regexp.escape(@account.support_email)}(.*)wrote:", Regexp::IGNORECASE)
    ] + sender_agnostic_regexes
  end

  def sender_agnostic_regexes
    @sender_agnostic_regexes ||= [
      Regexp.new("^.*On.*(\n)?wrote:$", Regexp::IGNORECASE),
      Regexp.new('^.*On(.*)(.*)wrote:$', Regexp::IGNORECASE),
      Regexp.new("-+original\s+message-+\s*$", Regexp::IGNORECASE),
      Regexp.new("from:\s*$", Regexp::IGNORECASE)
    ]
  end
end
