# Sends auto translate requests to the translation service the account picked in Settings.
class Captain::Conversation::TranslatorService
  pattr_initialize [:account!, { conversation_display_id: nil }]

  def provider
    account.translation_service
  end

  def translate(text, target_language)
    return google.translate(text, target_language).presence if google?

    Captain::Llm::MessageTranslationService.new(
      account: account, text: text, target_language: target_language, conversation_display_id: conversation_display_id
    ).perform[:message].presence
  rescue Google::Cloud::Error => e
    Rails.logger.warn("[AutoTranslate] Google translation failed: #{e.message}")
    nil
  end

  def language(text)
    return google.detect(text) if google?

    Captain::Llm::LanguageDetectionService.new(account: account, text: text).language
  rescue Google::Cloud::Error => e
    Rails.logger.warn("[AutoTranslate] Google language detection failed: #{e.message}")
    nil
  end

  private

  def google?
    provider == 'google_translate'
  end

  def google
    @google ||= Integrations::GoogleTranslate::ProcessorService.new(hook: account.google_translate_hook)
  end
end
