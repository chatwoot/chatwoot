class Captain::Conversation::TranslatorService
  pattr_initialize [:account!, { conversation_display_id: nil }]

  def provider
    account.translation_service
  end

  def translate(text, target_language)
    google? ? translate_with_google(text, target_language) : translate_with_captain(text, target_language)
  end

  def language(text)
    google? ? detect_with_google(text) : detect_with_captain(text)
  end

  private

  def google?
    provider == 'google_translate'
  end

  def translate_with_captain(text, target_language)
    response = Captain::Llm::MessageTranslationService.new(
      account: account, text: text, target_language: target_language, conversation_display_id: conversation_display_id
    ).perform
    response[:message].presence
  end

  def detect_with_captain(text)
    Captain::Llm::LanguageDetectionService.new(account: account, text: text).language
  end

  def translate_with_google(text, target_language)
    google.translate(text, target_language).presence
  rescue Google::Cloud::Error => e
    Rails.logger.warn("[AutoTranslate] Google translation failed: #{e.message}")
    nil
  end

  def detect_with_google(text)
    google.detect(text)
  rescue Google::Cloud::Error => e
    Rails.logger.warn("[AutoTranslate] Google language detection failed: #{e.message}")
    nil
  end

  def google
    @google ||= Integrations::GoogleTranslate::ProcessorService.new(hook: account.google_translate_hook)
  end
end
