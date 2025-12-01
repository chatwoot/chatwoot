class Whatsapp::CsatTemplateService
  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(template_config)
    base_name = template_config[:template_name] || 'customer_satisfaction_survey'
    template_name = generate_template_name(base_name)
    template_config_with_name = template_config.merge(template_name: template_name)
    request_body = build_template_request_body(template_config_with_name)
    response = send_template_creation_request(request_body)
    process_template_creation_response(response, template_config_with_name)
  end

  def delete_template(template_name = 'customer_satisfaction_survey')
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
    # Get current template to check if we already have a version number
    template = @whatsapp_channel.inbox.csat_config&.dig('template') || {}

    current_name = template['name']

    return base_name if current_name.blank?

    # Always use customer_satisfaction_survey as the true base, regardless of what's passed in
    true_base_name = 'customer_satisfaction_survey'

    if current_name.match?(/^customer_satisfaction_survey_(\d+)$/)
      # Extract current version and increment
      current_version = current_name.match(/^customer_satisfaction_survey_(\d+)$/)[1].to_i
      "#{true_base_name}_#{current_version + 1}"
    else
      # Second time or fallback - use version 1
      "#{true_base_name}_1"
    end
  end

  def build_template_request_body(template_config)
    {
      name: template_config[:template_name],
      language: template_config[:language] || 'en',
      category: 'MARKETING',
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

  def process_template_creation_response(response, template_config = {})
    if response.success?
      {
        success: true,
        template_id: response['id'],
        template_name: response['name'] || template_config[:template_name],
        language: template_config[:language] || 'en',
        status: 'PENDING'
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
end
