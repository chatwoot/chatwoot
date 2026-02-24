require 'google/cloud/translate/v3'

class Integrations::GoogleTranslate::ProcessorService
  pattr_initialize [:message!, :target_language!]

  # Google Translate API v3 limit: 30k codepoints per request
  MAX_CONTENT_LENGTH = 30_000

  def perform
    return if hook.blank?

    content = translation_content
    return if content.blank?

    content = content.truncate(MAX_CONTENT_LENGTH) if content.length > MAX_CONTENT_LENGTH

    response = client.translate_text(
      contents: [content],
      target_language_code: bcp47_language_code,
      parent: "projects/#{hook.settings['project_id']}",
      mime_type: mime_type
    )

    return if response.translations.first.blank?

    response.translations.first.translated_text
  rescue Google::Cloud::InvalidArgumentError => e
    # Fallback: if HTML is too long, retry with plain text content only
    if email_channel? && mime_type == 'text/html' && message.content.present?
      @fallback_to_plain_text = true
      retry
    end
    Rails.logger.error "Google Translate error for message #{message.id}: #{e.message}"
    nil
  end

  private

  def bcp47_language_code
    target_language.tr('_', '-')
  end

  def email_channel?
    message&.inbox&.email?
  end

  def email_content
    @email_content ||= {
      html: message.content_attributes.dig('email', 'html_content', 'full'),
      text: message.content_attributes.dig('email', 'text_content', 'full'),
      content_type: message.content_attributes.dig('email', 'content_type')
    }
  end

  def html_content_available?
    email_content[:html].present?
  end

  def plain_text_content_available?
    email_content[:content_type]&.include?('text/plain') &&
      email_content[:text].present?
  end

  def translation_content
    return message.content unless email_channel?
    return message.content if @fallback_to_plain_text
    return email_content[:html] if html_content_available?
    return email_content[:text] if plain_text_content_available?

    message.content
  end

  def mime_type
    if email_channel? && html_content_available? && !@fallback_to_plain_text
      'text/html'
    else
      'text/plain'
    end
  end

  def hook
    @hook ||= message.account.hooks.find_by(app_id: 'google_translate')
  end

  def client
    @client ||= ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
