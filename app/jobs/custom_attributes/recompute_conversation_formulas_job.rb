class CustomAttributes::RecomputeConversationFormulasJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    CustomAttributes::RecomputeConversationFormulasService.new(conversation: conversation).perform
  end
end
