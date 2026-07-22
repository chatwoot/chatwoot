class Captain::Llm::ConversationFaqJob < ApplicationJob
  queue_as :low

  def perform(conversation, assistant)
    inbox = conversation.inbox

    return unless conversation.resolved?
    return unless inbox.captain_active?

    return if assistant.config['feature_faq'].blank?

    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_suggestions
  end
end
