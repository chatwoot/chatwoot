class Whatsapp::Unoapi::GroupParticipantsSyncJob < ApplicationJob
  queue_as :low

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank? || !conversation.group?

    Whatsapp::Unoapi::GroupParticipantsSyncService.new(
      inbox: conversation.inbox,
      conversation: conversation
    ).perform
  end
end
