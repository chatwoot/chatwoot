class Captain::Conversation::DetectLanguageService
  # CLD3 labels short Latin texts confidently and wrongly ("get" => nl, "ok thanks" => el). Counting bytes keeps that
  # floor for Latin scripts while a few Chinese or Malayalam characters, which carry far more signal, still qualify.
  MIN_TEXT_BYTES = 20

  pattr_initialize [:message!]

  def self.language_of(text)
    return if text.to_s.bytesize < MIN_TEXT_BYTES

    result = CLD3::NNetLanguageIdentifier.new(0, 1000).find_language(text)
    result.language.to_s.split('-').first if result.reliable?
  end

  def perform
    return unless message.incoming?

    language = Captain::Conversation::MessageText.new(message).language
    conversation = message.conversation
    return if language.blank? || conversation.language == language
    # One line in the account language (a pasted error, a signature) must not switch replies back to it.
    return if conversation.language.present? && Captain::Llm::MessageTranslationService.same_language?(language, message.account.locale)

    conversation.update!(additional_attributes: conversation.additional_attributes.merge(conversation_language: language))
  end
end
