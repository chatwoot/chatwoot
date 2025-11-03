class Whatsapp::CsatTemplateService
  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(template_config)
    request_body = build_template_request_body(template_config)
    response = send_template_creation_request(request_body)
    process_template_creation_response(response)
  end

  def delete_template
    response = HTTParty.delete(
      "#{business_account_path}/message_templates?name=customer_satisfaction_survey",
      headers: api_headers
    )
    { success: response.success?, response_body: response.body }
  end

  def get_template_status(template_name)
    response = fetch_template_response(template_name)
    process_template_status_response(response)
  rescue StandardError => e
    Rails.logger.error "Error fetching template status: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def build_template_request_body(template_config)
    {
      name: 'customer_satisfaction_survey',
      language: template_config[:language] || 'en',
      category: 'UTILITY',
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
          text: template_config[:button_text] || 'Please rate us',
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

  def process_template_creation_response(response)
    if response.success?
      build_success_response(response)
    else
      build_error_response(response)
    end
  end

  def build_success_response(response)
    {
      success: true,
      template_id: response['id'],
      template_name: 'customer_satisfaction_survey',
      status: 'PENDING'
    }
  end

  def build_error_response(response)
    Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
    {
      success: false,
      error: 'Template creation failed',
      response_body: response.body
    }
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{@whatsapp_channel.provider_config['business_account_id']}"
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

  def fetch_template_response(template_name)
    HTTParty.get(
      "#{business_account_path}/message_templates?name=#{template_name}",
      headers: api_headers
    )
  end

  def process_template_status_response(response)
    if response.success? && response['data']&.any?
      build_template_status_success(response['data'].first)
    else
      { success: false, error: 'Template not found' }
    end
  end

  def build_template_status_success(template_data)
    {
      success: true,
      template: {
        id: template_data['id'],
        name: template_data['name'],
        status: template_data['status'],
        language: template_data['language']
      }
    }
  end
end
