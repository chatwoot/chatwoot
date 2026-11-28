require 'google/cloud/dialogflow/v2'

class Integrations::Dialogflow::ProcessorService < Integrations::BotProcessorService
  SUPPORTED_LANGUAGE_CODES = %w[
    ar
    en-US
    en-GB
    es-ES
    es-419
    fr-FR
    de-DE
    pt-BR
    pt-PT
    it-IT
    ja-JP
    ko-KR
    zh-CN
    zh-TW
    hi-IN
    ru-RU
    nl-NL
    pl-PL
    tr-TR
    th-TH
    vi-VN
    id-ID
  ].freeze
  AUTO_LANGUAGE_CODE_MAP = {
    'ar' => 'ar',
    'de' => 'de-DE',
    'en' => 'en-US',
    'es' => 'es-ES',
    'fr' => 'fr-FR',
    'hi' => 'hi-IN',
    'id' => 'id-ID',
    'it' => 'it-IT',
    'ja' => 'ja-JP',
    'ko' => 'ko-KR',
    'nl' => 'nl-NL',
    'pl' => 'pl-PL',
    'pt' => 'pt-BR',
    'ru' => 'ru-RU',
    'th' => 'th-TH',
    'tr' => 'tr-TR',
    'vi' => 'vi-VN',
    'zh' => 'zh-CN'
  }.freeze

  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def message_content(message)
    # TODO: might needs to change this to a way that we fetch the updated value from event data instead
    # cause the message.updated event could be that that the message was deleted

    return message.content_attributes['submitted_values']&.first&.dig('value') if event_name == 'message.updated'

    message.content
  end

  def get_response(session_id, message_content)
    unless configuration.valid_credentials? && configuration.valid_region?
      Rails.logger.warn "Dialogflow settings are invalid (account-#{hook.account_id}, hook-#{hook.id})"
      return
    end

    detect_intent(session_id, message_content)
  rescue Google::Cloud::PermissionDeniedError => e
    Rails.logger.warn "DialogFlow Error: (account-#{hook.try(:account_id)}, hook-#{hook.id}) #{e.message}"
    hook.prompt_reauthorization!
    hook.disable
  end

  def process_response(message, response)
    fulfillment_messages = response.query_result['fulfillment_messages']
    fulfillment_messages.each do |fulfillment_message|
      content_params = generate_content_params(fulfillment_message)
      if content_params['action'].present?
        process_action(message, content_params['action'])
      else
        create_conversation(message, content_params)
      end
    end
  end

  def generate_content_params(fulfillment_message)
    text_response = fulfillment_message['text'].to_h
    content_params = { content: text_response[:text].first } if text_response[:text].present?
    content_params ||= fulfillment_message['payload'].to_h
    content_params
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create!(
      content_params.merge(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
      )
    )
  end

  def configuration
    @configuration ||= Integrations::Dialogflow::Configuration.new(hook.settings)
  end

  def detect_intent(session_id, message)
    client = ::Google::Cloud::Dialogflow::V2::Sessions::Client.new do |config|
      config.timeout = 10.0
      config.credentials = configuration.client_credentials
      config.endpoint = configuration.endpoint
    end
    session = build_session_path(session_id)
    query_input = { text: { text: message, language_code: dialogflow_language_code } }
    client.detect_intent session: session, query_input: query_input
  end

  def build_session_path(session_id)
    project_id = hook.settings['project_id']
    region = configuration.region

    if region == 'global'
      "projects/#{project_id}/agent/sessions/#{session_id}"
    else
      "projects/#{project_id}/locations/#{region}/agent/sessions/#{session_id}"
    end
  end

  def dialogflow_language_code
    configured_language = hook.settings['language_code'].to_s.strip
    return 'en-US' if configured_language.blank?
    return configured_language if configured_language != 'auto'

    normalized_contact_language_code(conversation&.contact&.additional_attributes&.dig('language_code')) || 'en-US'
  end

  def normalized_contact_language_code(language_code)
    canonicalized_language_code = canonical_language_code(language_code)
    return if canonicalized_language_code.blank?
    return canonicalized_language_code if SUPPORTED_LANGUAGE_CODES.include?(canonicalized_language_code)

    AUTO_LANGUAGE_CODE_MAP[canonicalized_language_code] || AUTO_LANGUAGE_CODE_MAP[canonicalized_language_code.split('-', 2).first]
  end

  def canonical_language_code(language_code)
    normalized_language_code = language_code.to_s.tr('_', '-').strip
    return if normalized_language_code.blank?

    language, region = normalized_language_code.split('-', 2)
    return language.downcase if region.blank?

    "#{language.downcase}-#{region.upcase}"
  end
end
