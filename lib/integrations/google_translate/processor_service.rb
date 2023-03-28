class Integrations::GoogleTranslate::ProcessorService
  pattr_initialize [:message!, :target_language!]

  def perform
    return if message.content.blank?
    return if hook.blank?

    response = client.translate_text(
      contents: [message.content],
      target_language_code: target_language,
      parent: "projects/#{hook.settings['project_id']}"
    )

    return if response.translations.first.blank?

    response.translations.first.translated_text
  end

  private

  def hook
    @hook ||= message.account.hooks.find_by(app_id: 'google_translate')
  end

  def client
    @client ||= Google::Cloud::Translate.translation_service do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
