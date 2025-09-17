class Email::BaseBuilder
  pattr_initialize [:inbox!]

  private

  def channel
    @channel ||= inbox.channel
  end

  def account
    @account ||= inbox.account
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

  def custom_sender_name
    raise NotImplementedError, 'Subclasses must implement custom_sender_name'
  end
end
