require 'google/cloud/translate/v3'
class Integrations::GoogleTranslate::DetectLanguageService
  pattr_initialize [:hook!, :message!]

  def perform
    return unless valid_message?
    return if conversation.additional_attributes['conversation_language'].present?

    text = message.content[0...1500]
    response = client.detect_language(
      content: text,
      parent: "projects/#{hook.settings['project_id']}"
    )

    update_conversation(response)
  end

  private

  def valid_message?
    message.incoming? && message.content.present?
  end

  def conversation
    @conversation ||= message.conversation
  end

  def update_conversation(response)
    return if response&.languages.blank?

    conversation_language = response.languages.first.language_code
    additional_attributes = conversation.additional_attributes.merge({ conversation_language: conversation_language })
    conversation.update!(additional_attributes: additional_attributes)
    save_contact_locale(conversation_language)
  end

  def save_contact_locale(language)
    contact = conversation.contact
    return if contact.additional_attributes&.dig('locale').present?

    contact.update!(additional_attributes: (contact.additional_attributes || {}).merge('locale' => language))
  end

  def client
    @client ||= ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = hook.settings['credentials']
    end
  end
end
