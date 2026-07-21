class Captain::Llm::ConversationFaqJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    inbox = conversation.inbox

    return unless conversation.resolved?
    return unless inbox.captain_active?

    assistant = inbox.captain_assistant
    return if assistant.config['feature_faq'].blank?

    Captain::Llm::ConversationFaqService.new(assistant, conversation).generate_suggestions
  end
end
