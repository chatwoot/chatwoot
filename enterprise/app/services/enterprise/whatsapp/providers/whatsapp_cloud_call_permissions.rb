# Asking a WhatsApp contact for permission to call them: the free-form request inside the 24h window, and
# the template that carries it outside the window. Part of Enterprise::Whatsapp::Providers::WhatsappCloudService,
# whose request helpers it uses.
module Enterprise::Whatsapp::Providers::WhatsappCloudCallPermissions
  def send_call_permission_request(recipient, body_text = I18n.t('conversations.messages.whatsapp.call_permission_request_body'))
    response = HTTParty.post(
      "#{calls_phone_id_path}/messages", headers: api_headers, body: permission_request_body(recipient, body_text)
    )

    unless response.success?
      Rails.logger.error "[WHATSAPP CALL] send_call_permission_request failed: status=#{response.code} body=#{response.body}"
      return nil
    end

    response.parsed_response
  end

  # Creates a template whose call permission request can reach a contact outside the 24h window
  def create_call_permission_template(name:, language:, body:)
    response = HTTParty.post(
      "#{calls_business_account_path}/message_templates", headers: template_api_headers,
                                                          body: call_permission_template_body(name, language, body)
    )
    return true if response.success?

    Rails.logger.error "[WHATSAPP CALL] create_call_permission_template failed: status=#{response.code} body=#{response.body}"
    false
  end

  # Finds a template made earlier, such as one for a message the inbox has switched back to
  def call_permission_template_exists?(name:, language:)
    response = HTTParty.get(
      "#{calls_business_account_path}/message_templates", headers: template_api_headers, query: { name: name, fields: 'name,language' }
    )
    return false unless response.success?

    Array(response.parsed_response['data']).any? { |template| template['name'] == name && template['language'] == language }
  end

  def send_call_permission_template(recipient, name:, language:)
    response = HTTParty.post(
      "#{calls_phone_id_path}/messages", headers: api_headers, body: permission_template_message_body(recipient, name, language)
    )

    unless response.success?
      Rails.logger.error "[WHATSAPP CALL] send_call_permission_template failed: status=#{response.code} body=#{response.body}"
      return nil
    end

    response.parsed_response
  end

  private

  def calls_business_account_path
    base = ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
    fallback = Enterprise::Whatsapp::Providers::WhatsappCloudService::WHATSAPP_CALLING_API_VERSION_FALLBACK
    version = GlobalConfigService.load('WHATSAPP_API_VERSION', fallback)
    "#{base}/#{version}/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  # Managing templates can need a different token than sending messages, as in template sync
  def template_api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.template_access_token}", 'Content-Type' => 'application/json' }
  end

  # Component types as in Meta's call permission template example
  def call_permission_template_body(name, language, body)
    {
      name: name, language: language, category: 'UTILITY',
      components: [{ type: 'BODY', text: body }, { type: 'call_permission_request' }]
    }.to_json
  end

  def permission_template_message_body(recipient, name, language)
    {
      messaging_product: 'whatsapp', recipient_type: 'individual', **recipient_params(recipient),
      type: 'template',
      template: { name: name, language: { policy: 'deterministic', code: language } }
    }.to_json
  end

  def permission_request_body(recipient, body_text)
    {
      messaging_product: 'whatsapp', recipient_type: 'individual', **recipient_params(recipient),
      type: 'interactive',
      interactive: {
        type: 'call_permission_request',
        action: { name: 'call_permission_request' },
        body: { text: body_text }
      }
    }.to_json
  end
end
