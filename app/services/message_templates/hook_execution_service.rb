class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if should_send_email_collect?
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def should_send_email_collect?
    return unless conversation.inbox.web_widget?
    return unless conversation.messages.outgoing.count.zero?
    return unless conversation.messages.template.count.zero?

    true
  end
end
