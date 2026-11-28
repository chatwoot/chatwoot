class Email::SendOnEmailService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Email
  end

  def perform_reply
    return unless message.email_notifiable_message?

    reply_mail = deliver_reply_mail
    Rails.logger.info("Email message #{message.id} sent with source_id: #{reply_mail.message_id}")
    message.update(source_id: reply_mail.message_id)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: message.account).capture_exception
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def deliver_reply_mail
    reply_mail = ConversationReplyMailer.with(account: message.account).email_reply(message).deliver_now
    # ApplicationMailer rescues SMTP exceptions, so deliver_now returns the exception instead of the mail
    raise reply_mail if reply_mail.is_a?(Exception)

    reply_mail
  end
end
