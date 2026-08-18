class Email::BaseBuilder
  include EmailAddressParseable

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

  # Builds "display name <email>" via Mail::Address so the display name is
  # quoted per RFC 5322 and characters like commas can't split the mailbox.
  def sender_name(sender_email)
    # Friendly: <agent_name> from <business_name>
    # Professional: <business_name>
    address = Mail::Address.new
    address.address = sender_email
    address.display_name = if inbox.friendly?
                             I18n.t(
                               'conversations.reply.email.header.friendly_display_name',
                               sender_name: custom_sender_name,
                               business_name: business_name
                             )
                           else
                             business_name
                           end
    address.format
  end

  def business_name
    inbox.sanitized_business_name
  end

  def account_support_email
    # Parse the email to ensure it's in the correct format, the user
    # can save it in the format "Name <email@domain.com>"
    parse_email(account.support_email)
  end
end
