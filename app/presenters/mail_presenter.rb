class MailPresenter < SimpleDelegator
  attr_accessor :mail

  def initialize(mail)
    super(mail)
    @mail = mail
  end

  def subject
    encode_to_unicode(@mail.subject)
  end

  def content
    return @decoded_content if @decoded_content

    @decoded_content = parts.present? ? parts[0].body.decoded : decoded
    @decoded_content = encode_to_unicode(@decoded_content)
    @decoded_content
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
      content: content,
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
    str.encode(current_encoding, 'UTF-8', invalid: :replace, undef: :replace, replace: '?')
  end
end
