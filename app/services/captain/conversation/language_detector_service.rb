class Captain::Conversation::LanguageDetectorService
  pattr_initialize [:assistant!]

  CLD3_MIN_PROBABILITY = 0.5
  CLD3_MAX_TEXT_BYTES = 1000

  # Detects the language of the conversation from the LAST human message and
  # returns an ISO-639-1 code (e.g. 'id', 'en'). Falls back to the assistant's
  # account locale when detection is unreliable or there is no human message.
  # This is the single source of truth for the reply language, reused by the
  # agent instructions, simple replies, RAG query translation, and handoff
  # messaging.
  def detect(message_history = [])
    detected_language = detect_from_last_human_message(message_history)
    detected_language.presence || account_language_code
  end

  private

  def detect_from_last_human_message(message_history)
    text = last_human_message_text(message_history)
    return if text.blank?

    result = detector.find_language(text)
    return unless result.reliable? && result.probability >= CLD3_MIN_PROBABILITY

    result.language
  rescue StandardError
    nil
  end

  def detector
    @detector ||= CLD3::NNetLanguageIdentifier.new(0, CLD3_MAX_TEXT_BYTES)
  end

  def last_human_message_text(message_history)
    last_user_message = message_history.reverse.find { |message| message[:role] == 'user' }
    return if last_user_message.blank?

    content = last_user_message[:content]
    return content.to_s unless content.is_a?(Array)

    text, = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    text.to_s
  end

  def account_language_code
    locale = @assistant.account.locale.presence || I18n.default_locale.to_s
    locale.split('_').first.downcase
  end
end
