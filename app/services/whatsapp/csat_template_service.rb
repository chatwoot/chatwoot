class Whatsapp::CsatTemplateService
  DEFAULT_BUTTON_TEXT = 'Please rate us'.freeze
  DEFAULT_LANGUAGE = 'en'.freeze
  WHATSAPP_API_VERSION = 'v14.0'.freeze
  TEMPLATE_CATEGORY = 'MARKETING'.freeze
  TEMPLATE_STATUS_PENDING = 'PENDING'.freeze

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(template_config)
    base_name = template_config[:template_name]
    template_name = generate_template_name(base_name)
    template_config_with_name = template_config.merge(template_name: template_name)
    request_body = build_template_request_body(template_config_with_name)
    response = send_template_creation_request(request_body)
    process_template_creation_response(response, template_config_with_name)
  end

  def delete_template(template_name = nil)
    template_name ||= CsatTemplateNameService.csat_template_name(@whatsapp_channel.inbox.id)
    response = HTTParty.delete(
      "#{business_account_path}/message_templates?name=#{template_name}",
      headers: api_headers
    )
    { success: response.success?, response_body: response.body }
  end

  def get_template_status(template_name)
    response = HTTParty.get("#{business_account_path}/message_templates?name=#{template_name}", headers: api_headers)

    if response.success? && response['data']&.any?
      template_data = response['data'].first
      {
        success: true,
        template: {
          id: template_data['id'], name: template_data['name'],
          status: template_data['status'], language: template_data['language']
        }
      }
    else
      { success: false, error: 'Template not found' }
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching template status: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def generate_template_name(base_name)
    current_template_name = current_template_name_from_config
    CsatTemplateNameService.generate_next_template_name(base_name, @whatsapp_channel.inbox.id, current_template_name)
  end

  def current_template_name_from_config
    @whatsapp_channel.inbox.csat_config&.dig('template', 'name')
  end

  def build_template_request_body(template_config)
    {
      name: template_config[:template_name],
      language: template_config[:language] || DEFAULT_LANGUAGE,
      category: TEMPLATE_CATEGORY,
      components: build_template_components(template_config)
    }
  end

  def build_template_components(template_config)
    [
      build_body_component(template_config[:message]),
      build_buttons_component(template_config)
    ]
  end

  def build_body_component(message)
    {
      type: 'BODY',
      text: message
    }
  end

  def build_buttons_component(template_config)
    {
      type: 'BUTTONS',
      buttons: [
        {
          type: 'URL',
          text: template_config[:button_text] || DEFAULT_BUTTON_TEXT,
          url: "#{template_config[:base_url]}/survey/responses/{{1}}",
          example: ['12345']
        }
      ]
    }
  end

  def send_template_creation_request(request_body)
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def process_template_creation_response(response, template_config = {})
    if response.success?
      {
        success: true,
        template_id: response['id'],
        template_name: response['name'] || template_config[:template_name],
        language: template_config[:language] || DEFAULT_LANGUAGE,
        status: TEMPLATE_STATUS_PENDING
      }
    else
      Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
      {
        success: false,
        error: 'Template creation failed',
        response_body: response.body
      }
    end
  end

  def business_account_path
    "#{api_base_path}/#{WHATSAPP_API_VERSION}/#{@whatsapp_channel.provider_config['business_account_id']}"
  end

  def api_headers
    {
      'Authorization' => "Bearer #{@whatsapp_channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end
end
