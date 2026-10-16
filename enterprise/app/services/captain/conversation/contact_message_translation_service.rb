class Captain::Conversation::ContactMessageTranslationService
  pattr_initialize [:conversation!, :message_ids!, :target_language!]

  def perform
    conversation.messages.where(id: message_ids).find_each do |message|
      Captain::Conversation::MessageTranslationJob.perform_later(message, target_language)
    end
  end
end
