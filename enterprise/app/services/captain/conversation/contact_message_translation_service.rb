class Captain::Conversation::ContactMessageTranslationService
  pattr_initialize [:message!, :target_language!]

  def perform
    return if message.translations&.key?(target_language)

    translation = text_in_agent_language

    # Two agents with different languages can open the same conversation, so two jobs may translate this message at once.
    # with_lock reloads the message before saving, so the translation the other job saved is kept instead of overwritten.
    message.with_lock do
      next if message.deleted

      if translation
        message.translations = message.translations.to_h.merge(target_language => translation)
        message.translation_failed = nil
      else
        message.translation_failed = true
      end
      message.save!
    end
  end

  private

  delegate :conversation, to: :message

  def text_in_agent_language
    language = Captain::Conversation::MessageLanguageService.new(conversation: conversation, message: message).perform
    return message.content if Captain::Llm::MessageTranslationService.same_language?(language, target_language)

    Captain::Llm::MessageTranslationService.new(
      account: message.account, text: message.content, target_language: target_language, conversation_display_id: conversation.display_id
    ).perform[:message].presence
  end
end
