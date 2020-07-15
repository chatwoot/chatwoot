class ConversationReplyMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  def reply_with_summary(conversation, message_queued_time)
    return unless smtp_config_set_or_development?

    @conversation = conversation
    @account = @conversation.account
    @contact = @conversation.contact
    @agent = @conversation.assignee

    recap_messages = @conversation.messages.chat.where('created_at < ?', message_queued_time).last(10)
    new_messages = @conversation.messages.chat.where('created_at >= ?', message_queued_time)

    @messages = recap_messages + new_messages
    @messages = @messages.select(&:reportable?)

    mail({
           to: @contact&.email,
           from: from_email,
           reply_to: reply_email,
           subject: mail_subject,
           message_id: custom_message_id,
           in_reply_to: in_reply_to_email
         })
  end

  def reply_without_summary(conversation, message_queued_time)
    return unless smtp_config_set_or_development?

    @conversation = conversation
    @account = @conversation.account
    @contact = @conversation.contact
    @agent = @conversation.assignee

    @messages = @conversation.messages.outgoing.where('created_at >= ?', message_queued_time)

    mail({
           to: @contact&.email,
           from: from_email,
           reply_to: reply_email,
           subject: mail_subject,
           message_id: custom_message_id,
           in_reply_to: in_reply_to_email
         })
  end

  private

  def mail_subject
    subject_line = I18n.t('conversations.reply.email_subject')
    "[##{@conversation.display_id}] #{subject_line}"
  end

  def reply_email
    if custom_domain_email_enabled?
      "reply+to+#{@conversation.uuid}@#{@account.domain}"
    else
      @agent&.email
    end
  end

  def from_email
    if custom_domain_email_enabled? && @account.support_email.present?
      @account.support_email
    else
      ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
    end
  end

  def custom_message_id
    "<conversation/#{@conversation.uuid}/messages/#{@messages&.last&.id}@#{current_domain}>"
  end

  def in_reply_to_email
    "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{current_domain}>"
  end

  def custom_domain_email_enabled?
    @custom_domain_email_enabled ||= @account.domain_emails_enabled? && @account.domain.present?
  end

  def current_domain
    if custom_domain_email_enabled? && @account.domain
      @account.domain
    else
      GlobalConfig.get('FALLBACK_DOMAIN')['FALLBACK_DOMAIN']
    end
  end
end
