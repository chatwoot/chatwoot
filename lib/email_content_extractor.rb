class EmailContentExtractor
  attr_accessor :mail

  delegate :subject,
           :message_id,
           :to,
           :from,
           :in_reply_to,
           :cc,
           :bcc,
           to: :mail

  def initialize(mail)
    @mail = mail
  end

  def content
    if mail.parts.present?
      mail.parts[0].body.decoded
    else
      mail.decoded
    end
  end

  def attachments
    mail.attachments.map(&:decode)
  end

  def number_of_attachments
    mail.attachments.count
  end
end
