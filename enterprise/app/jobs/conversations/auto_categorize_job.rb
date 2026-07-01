class Conversations::AutoCategorizeJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?
    return unless conversation.account.feature_enabled?('auto_categorization')

    # Ensure the conversation has enough context (e.g. 3+ messages)
    # or skip if it's already assigned/prioritized. We'll simply trigger the LLM service.
    Captain::Llm::AutoCategorizationService.new(conversation).perform
  end
end
