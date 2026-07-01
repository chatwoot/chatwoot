class Conversations::EvaluateAutoQaJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    Captain::Llm::AutoQaService.new(conversation).perform
  end
end
