class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if should_send_email_collect?
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def first_message_from_contact?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def should_send_email_collect?
    conversation.inbox.web_widget? && first_message_from_contact?
  end
end
