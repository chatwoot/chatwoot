class Email::BaseBuilder
  pattr_initialize [:inbox!]

  private

  def channel
    @channel ||= inbox.channel
  end

  def account
    @account ||= inbox.account
  end

  def conversation
    @conversation ||= message.conversation
  end

  def custom_sender_name
    message&.sender&.available_name || I18n.t('conversations.reply.email.header.notifications')
  end

  def sender_name(sender_email)
    # Friendly: <agent_name> from <business_name>
    # Professional: <business_name>
    if inbox.friendly?
      I18n.t(
        'conversations.reply.email.header.friendly_name',
        sender_name: custom_sender_name,
        business_name: business_name,
        from_email: sender_email
      )
    else
      I18n.t(
        'conversations.reply.email.header.professional_name',
        business_name: business_name,
        from_email: sender_email
      )
    end
  end

  def business_name
    inbox.business_name || inbox.sanitized_name
  end

  def account_support_email
    # Parse the email to ensure it's in the correct format, the user
    # can save it in the format "Name <email@domain.com>"
    parse_email(account.support_email)
  end

  def parse_email(email_string)
    Mail::Address.new(email_string).address
  end
end
