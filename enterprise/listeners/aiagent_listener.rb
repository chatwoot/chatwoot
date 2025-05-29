class AiagentListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    topic = conversation.inbox.aiagent_topic
    return unless conversation.inbox.aiagent_active?

    Aiagent::Llm::ContactNotesService.new(topic, conversation).generate_and_update_notes if topic.config['feature_memory'].present?
    Aiagent::Llm::ConversationFaqService.new(topic, conversation).generate_and_deduplicate if topic.config['feature_faq'].present?
  end
end
