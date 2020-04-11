class EmailContentExtractor < SimpleDelegator
  attr_accessor :mail

  def initialize(mail)
    super(mail)
    @mail = mail
  end

  def content
    if parts.present?
      parts[0].body.decoded
    else
      decoded
    end
  end

  def attachments
    mail.attachments.map(&:decode)
  end

  def number_of_attachments
    mail.attachments.count
  end

  def serialized_data
    {
      content: content,
      number_of_attachments: number_of_attachments,
      subject: subject,
      to: to,
      from: from,
      in_reply_to: in_reply_to,
      cc: cc,
      bcc: bcc,
      source_id: source_id,
      message_id: message_id
    }
  end
end
