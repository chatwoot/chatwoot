class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if should_send_email_collect?
  end

  private

  delegate :contact, to: :conversation

  def inbox
    @inbox ||= message.inbox
  end

  def conversation
    @conversation ||= message.conversation
  end

  def should_send_email_collect?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end
end
