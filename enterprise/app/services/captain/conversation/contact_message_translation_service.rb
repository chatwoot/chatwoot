class Captain::Conversation::ContactMessageTranslationService
  pattr_initialize [:message!, :target_language!]

  def perform
    language = Captain::Conversation::MessageLanguageService.new(conversation: message.conversation, message: message).perform
    # A message already in the agent's language is its own translation.
    translation = same_language?(language) ? message.content : translate
    save_translation(translation)
  end

  private

  # Two agents with different languages can open the same conversation, so two jobs may translate this message at once.
  # with_lock reloads the message before saving, so the translation the other job saved is kept instead of overwritten.
  def save_translation(translation)
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

  def same_language?(language)
    Captain::Llm::MessageTranslationService.same_language?(language, target_language)
  end

  def translate
    response = Captain::Llm::MessageTranslationService.new(
      account: message.account,
      text: message.content,
      target_language: target_language,
      conversation_display_id: message.conversation.display_id
    ).perform
    Rails.logger.warn("[AutoTranslate] message #{message.id} not translated: #{response[:error]}") if response[:error]
    response[:message].presence
  end
end
