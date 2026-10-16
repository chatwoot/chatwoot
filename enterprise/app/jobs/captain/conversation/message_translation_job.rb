class Captain::Conversation::MessageTranslationJob < ApplicationJob
  queue_as :default

  def perform(message, target_language)
    language = message.source_language || detect_language(message)
    translation = same_language?(language, target_language) ? message.content : translate(message, target_language)

    # Two agents with different languages can open the same conversation, so two jobs may translate this message at once.
    # with_lock reloads the message before saving, so the translation the other job saved is kept instead of overwritten.
    message.with_lock do
      message.source_language = language
      if translation
        message.translations = message.translations.to_h.merge(target_language => translation)
        message.translation_failed = nil
      else
        message.translation_failed = true
      end
      message.save!
    end

    update_conversation_language(message, language)
  end

  private

  def same_language?(language, target_language)
    Captain::Llm::MessageTranslationService.same_language?(language, target_language)
  end

  def detect_language(message)
    Captain::Llm::LanguageDetectionService.new(account: message.account, text: message.content).language
  end

  def translate(message, target_language)
    response = Captain::Llm::MessageTranslationService.new(
      account: message.account,
      text: message.content,
      target_language: target_language,
      conversation_display_id: message.conversation.display_id
    ).perform
    Rails.logger.warn("[AutoTranslate] message #{message.id} not translated: #{response[:error]}") if response[:error]
    response[:message].presence
  end

  # The conversation follows the language of the contact's latest message, so a switch midway is picked up.
  def update_conversation_language(message, language)
    conversation = message.conversation
    return if language.blank? || language == conversation.language
    return unless message.incoming? && message.id == conversation.messages.incoming.maximum(:id)

    conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => language))
  end
end
