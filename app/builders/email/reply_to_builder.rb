class Email::ReplyToBuilder < Email::BaseBuilder
  pattr_initialize [:inbox!, :conversation!]

  def build
    reply_to = if inbox.email?
                 channel.email
               elsif inbound_email_enabled?
                 "reply+#{conversation.uuid}@#{account.inbound_email_domain}"
               else
                 account.support_email
               end

    sender_name(reply_to)
  end

  private

  def inbound_email_enabled?
    account.feature_enabled?('inbound_emails') && account.inbound_email_domain.present?
  end

  def custom_sender_name
    conversation.assignee&.available_name || I18n.t('conversations.reply.email.header.notifications')
  end
end
