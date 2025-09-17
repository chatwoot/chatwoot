class Messages::SendEmailNotificationService
  pattr_initialize [:message!]

  def perform
    return unless should_send_email_notification?

    conversation = message.conversation
    conversation_mail_key = format(::Redis::Alfred::CONVERSATION_MAILER_KEY, conversation_id: conversation.id)

    # will set a redis key for the conversation so that we don't need to send email for every new message
    # last few messages coupled together is sent every 2 minutes rather than one email for each message
    # if redis key exists there is an unprocessed job that will take care of delivering the email
    return if Redis::Alfred.get(conversation_mail_key).present?

    Redis::Alfred.setex(conversation_mail_key, message.id)
    ConversationReplyEmailWorker.perform_in(2.minutes, conversation.id, message.id)
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
