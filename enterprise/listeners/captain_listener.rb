class CaptainListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    assistant = conversation.inbox.captain_assistant
    return unless conversation.inbox.captain_active?

    Captain::Llm::ContactNotesService.new(assistant, conversation).generate_and_update_notes if assistant.config['feature_memory'].present?
    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_and_deduplicate if assistant.config['feature_faq'].present?
  end
end
