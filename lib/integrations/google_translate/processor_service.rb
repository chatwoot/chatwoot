require 'google/cloud/translate/v3'

class Integrations::GoogleTranslate::ProcessorService
  pattr_initialize [:hook!]

  def translate_message(message, target_language)
    content, mime_type = message_content(message)
    translate(content, target_language, mime_type: mime_type) if content.present?
  end

  def translate(text, target_language, mime_type: 'text/plain')
    response = client.translate_text(
      contents: [text], target_language_code: target_language.tr('_', '-'), parent: parent, mime_type: mime_type
    )
    response.translations.first&.translated_text
  end

  def detect(text)
    code = client.detect_language(content: text[0...1500], parent: parent).languages.first&.language_code
    code unless code.blank? || code == 'und'
  end

  private

  def message_content(message)
    email = message.content_attributes['email'].to_h if message.inbox.email?
    return [message.content, 'text/plain'] if email.blank?

    html = email.dig('html_content', 'full')
    text = email.dig('text_content', 'full')
    return [html, 'text/html'] if html.present?
    return [text, 'text/plain'] if email['content_type']&.include?('text/plain') && text.present?

    [message.content, 'text/plain']
  end

  def parent
    "projects/#{hook.settings['project_id']}"
  end

  def client
    @client ||= ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
