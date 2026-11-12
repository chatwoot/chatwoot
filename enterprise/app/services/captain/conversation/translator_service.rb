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

  # The account owns the Google key. A broken key fails in Google's auth library with errors outside
  # Google::Cloud::Error, such as Signet, OpenSSL or a bare RuntimeError. Any of them must leave the reply
  # untranslated instead of stopping the job that sends it.
  def translate_with_google(text, target_language)
    google.translate(text, target_language).presence
  rescue StandardError => e
    log_google_failure('translation', e)
    nil
  end

  def detect_with_google(text)
    google.detect(text)
  rescue StandardError => e
    log_google_failure('language detection', e)
    nil
  end

  def log_google_failure(operation, error)
    Rails.logger.error("[AutoTranslate] Google #{operation} failed for account #{account.id}: #{error.class}: #{error.message}")
  end

  def google
    @google ||= Integrations::GoogleTranslate::ProcessorService.new(hook: account.google_translate_hook)
  end
end
