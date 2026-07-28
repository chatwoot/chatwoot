class CaptainListener < BaseListener
  include ::Events::Types

  def message_created(event)
    message = event.data[:message]
    return unless message.outgoing? && !message.private? && message.sender_type == 'Captain::Assistant'

    Captain::ConversationOutcomeTracker.new(conversation: message.conversation, assistant: message.sender)
                                       .record_captain_reply(message: message)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant

    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqJob.perform_later(conversation, assistant) if assistant.config['feature_faq'].present?
  end
end
