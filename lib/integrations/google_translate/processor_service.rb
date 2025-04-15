require 'google/cloud/translate/v3'

class Integrations::GoogleTranslate::ProcessorService
  pattr_initialize [:message!, :target_language!, :inbox]

  def perform
    return if hook.blank?

    content = determine_translation_content
    return if content.blank?

    response = client.translate_text(
      contents: [content],
      target_language_code: target_language,
      parent: "projects/#{hook.settings['project_id']}",
      mime_type: determine_mime_type
    )

    return if response.translations.first.blank?

    response.translations.first.translated_text
  end

  private

  def email_channel?
    inbox&.channel_type == 'Channel::Email'
  end

  def email_content
    @email_content ||= {
      html: message.content_attributes.dig('email', 'html_content', 'full'),
      text: message.content_attributes.dig('email', 'text_content', 'full'),
      content_type: message.content_attributes.dig('email', 'content_type')
    }
  end

  def determine_translation_content
    return message.content unless email_channel?

    if email_content[:html].present?
      email_content[:html]
    elsif email_content[:content_type]&.include?('text/plain') && email_content[:text].present?
      email_content[:text]
    else
      message.content
    end
  end

  def determine_mime_type
    if email_channel? && email_content[:html].present?
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
