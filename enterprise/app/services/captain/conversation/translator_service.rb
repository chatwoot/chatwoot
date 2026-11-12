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

  # True once a call to the provider has failed. A blank language alone can also mean the text was too short to tell.
  def failed?
    @failed.present?
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
    detection = Captain::Llm::LanguageDetectionService.new(account: account, text: text)
    language = detection.language
    @failed = true if detection.failed?
    language
  end

  def translate_with_google(text, target_language)
    with_google_fallback('translation') { google.translate(text, target_language).presence }
  end

  def detect_with_google(text)
    with_google_fallback('language detection') { google.detect(text) }
  end

  # A failed Google call leaves the text untranslated instead of stopping the job that sends the reply.
  # The account owns the key, so key errors are only logged. Any other error is ours and is reported.
  def with_google_fallback(operation)
    yield
  rescue *Integrations::GoogleTranslate::CredentialsValidator::KEY_ERRORS => e
    @failed = true
    Rails.logger.error("[AutoTranslate] Google #{operation} failed for account #{account.id}: #{e.class}: #{e.message}")
    nil
  rescue StandardError => e
    @failed = true
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    nil
  end

  def google
    @google ||= Integrations::GoogleTranslate::ProcessorService.new(hook: account.google_translate_hook)
  end
end
