class Messages::SendEmailNotificationService
  pattr_initialize [:message!]

  def perform
    return unless should_send_email_notification?

    conversation = message.conversation
    conversation_mail_key = format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)

    # Atomically set redis key to prevent duplicate email workers. Keep the key alive longer than
    # the worker delay (1 hour) so slow queues don't enqueue duplicate jobs, but let it expire if
    # the worker never manages to clean up.
    return unless Redis::Alfred.set(conversation_mail_key, message.id, nx: true, ex: 1.hour.to_i)

    ConversationReplyEmailJob.set(wait: 2.minutes).perform_later(conversation.id, message.id)
  end

  private

  def should_send_email_notification?
    return false unless message.email_notifiable_message?
    return false if message.conversation.contact.email.blank?

    email_reply_enabled?
  end

  def email_reply_enabled?
    inbox = message.inbox
    case inbox.channel.class.to_s
    when 'Channel::WebWidget'
      inbox.channel.continuity_via_email
    when 'Channel::Api'
      inbox.account.feature_enabled?('email_continuity_on_api_channel')
    else
      false
    end
  end
end
