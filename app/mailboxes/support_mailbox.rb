class SupportMailbox < ApplicationMailbox
  MATCHER = /[a-z]+@support.chatwoot.com/i

  def process
    if inbox.present?
      ::EmailInbox::CreateConversationService.new(
        account: account,
        message: message_params
      ).perform
    end
  end

  private

  def account
    inbox.account
  end

  def inbox
    @inbox ||= EmailInbox.find_by(email: inbox_email)
  end

  def inbox_email
    recipient = mail.recipients.find{ |r| MATCHER.match?(r) }
    recipient[MATCHER, 1]
  end

  def message_params
    {
      from: mail.envelope_from,
      subject: mail.subject,
      content: mail.parts.map { |p| p.decoded }
    }
  end
end
