require 'google/cloud/translate/v3'

class Integrations::GoogleTranslate::TextService
  pattr_initialize [:hook!]

  def translate(text, target_language)
    response = client.translate_text(
      contents: [text], target_language_code: target_language.tr('_', '-'), parent: parent, mime_type: 'text/plain'
    )
    response.translations.first&.translated_text
  end

  def detect(text)
    code = client.detect_language(content: text[0...1500], parent: parent).languages.first&.language_code
    code unless code.blank? || code == 'und'
  end

  private

  def parent
    "projects/#{hook.settings['project_id']}"
  end

  def client
    @client ||= ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
