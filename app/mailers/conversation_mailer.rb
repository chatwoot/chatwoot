class ConversationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_SENDER_EMAIL', 'accounts@chatwoot.com')
  layout 'mailer'

  def new_message(conversation, message_queued_time)
    return unless smtp_config_set_or_development?

    @conversation = conversation
    @contact = @conversation.contact
    @agent = @conversation.assignee

    recap_messages = @conversation.messages.where('created_at < ?', message_queued_time).order(created_at: :asc).last(10)
    new_messages = @conversation.messages.where('created_at >= ?', message_queued_time)

    @messages = recap_messages + new_messages
    @messages = @messages.select(&:reportable?)

    mail(to: @contact&.email, from: @agent&.email, subject: mail_subject(@messages.last))
  end

  private

  def mail_subject(last_message, trim_length = 30)
    "[##{@conversation.display_id}] #{last_message.content.truncate(trim_length)}"
  end
end
