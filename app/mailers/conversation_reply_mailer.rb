class ConversationReplyMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout :choose_layout

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

    @messages = @conversation.messages.chat.outgoing.where('created_at >= ?', message_queued_time)
    return false if @messages.count.zero?

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
    if inbound_email_enabled?
      "#{@agent.available_name} <reply+#{@conversation.uuid}@#{current_domain}>"
    else
      @agent&.email
    end
  end

  def from_email
    if inbound_email_enabled?
      "#{@agent.available_name} <#{account_support_email}>"
    else
      "#{@agent.available_name} <#{ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')}>"
    end
  end

  def custom_message_id
    "<conversation/#{@conversation.uuid}/messages/#{@messages&.last&.id}@#{current_domain}>"
  end

  def in_reply_to_email
    "<account/#{@account.id}/conversation/#{@conversation.uuid}@#{current_domain}>"
  end

  def inbound_email_enabled?
    @inbound_email_enabled ||= @account.feature_enabled?('inbound_emails') && current_domain.present? && account_support_email.present?
  end

  def current_domain
    @current_domain ||= begin
      @account.domain ||
        ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN', false) ||
        GlobalConfig.get('MAILER_INBOUND_EMAIL_DOMAIN')['MAILER_INBOUND_EMAIL_DOMAIN']
    end
  end

  def account_support_email
    @account_support_email ||= begin
      @account.support_email ||
        GlobalConfig.get('MAILER_SUPPORT_EMAIL')['MAILER_SUPPORT_EMAIL'] ||
        ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
    end
  end

  def choose_layout
    return false if action_name == 'reply_without_summary'

    'mailer'
  end
end
