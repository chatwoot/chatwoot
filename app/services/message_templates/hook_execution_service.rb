class MessageTemplates::HookExecutionService
  pattr_initialize [:message!]

  def perform
    return if inbox.agent_bot_inbox&.active?

    ::MessageTemplates::Template::Greeting.new(conversation: conversation).perform if should_send_greeting?

    ::MessageTemplates::Template::EmailCollect.new(conversation: conversation).perform if should_send_email_collect?
  end

  private

  delegate :inbox, :conversation, to: :message
  delegate :contact, to: :conversation

  def first_message_from_contact?
    conversation.messages.outgoing.count.zero? && conversation.messages.template.count.zero?
  end

  def should_send_greeting?
    first_message_from_contact? && conversation.inbox.greeting_enabled?
  end

  def email_collect_was_sent?
    conversation.messages.where(content_type: 'input_email').present?
  end

  def should_send_email_collect?
    !contact_has_email? && conversation.inbox.web_widget? && !email_collect_was_sent?
  end

  def contact_has_email?
    contact.email
  end
end
