class Whatsapp::TemplateCreatorService
  WHATSAPP_API_VERSION = 'v22.0'.freeze
  TEMPLATE_STATUS_PENDING = 'PENDING'.freeze
  DEFAULT_LANGUAGE = 'pt_BR'.freeze

  NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/
  BODY_MAX_LENGTH = 1024
  HEADER_MAX_LENGTH = 60
  FOOTER_MAX_LENGTH = 60
  BUTTON_TEXT_MAX_LENGTH = 25
  MAX_BUTTONS = 10

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create_template(params)
    errors = validate_params(params)
    return { success: false, errors: errors } if errors.any?

    request_body = build_request_body(params)
    response = submit_to_meta(request_body)
    process_response(response, params)
  end

  private

  def validate_params(params)
    errors = []
    errors << 'Name is required' if params[:name].blank?
    errors << 'Name must be snake_case (lowercase letters, numbers, underscores)' if params[:name].present? && !params[:name].match?(NAME_PATTERN)
    errors << 'Body text is required' if params[:body_text].blank?
    errors << "Body text exceeds #{BODY_MAX_LENGTH} characters" if params[:body_text].present? && params[:body_text].length > BODY_MAX_LENGTH
    errors << "Header text exceeds #{HEADER_MAX_LENGTH} characters" if params[:header_text].present? && params[:header_text].length > HEADER_MAX_LENGTH
    errors << "Footer text exceeds #{FOOTER_MAX_LENGTH} characters" if params[:footer_text].present? && params[:footer_text].length > FOOTER_MAX_LENGTH

    if params[:buttons].present?
      errors << "Maximum #{MAX_BUTTONS} buttons allowed" if params[:buttons].length > MAX_BUTTONS
      params[:buttons].each_with_index do |btn, idx|
        errors << "Button #{idx + 1} text exceeds #{BUTTON_TEXT_MAX_LENGTH} characters" if btn[:text].present? && btn[:text].length > BUTTON_TEXT_MAX_LENGTH
      end
    end

    errors
  end

  def build_request_body(params)
    {
      name: params[:name],
      language: params[:language].presence || DEFAULT_LANGUAGE,
      category: params[:category].presence || 'UTILITY',
      components: build_components(params)
    }
  end

  def build_components(params)
    components = []
    components << build_header_component(params[:header_text]) if params[:header_text].present?
    components << build_body_component(params[:body_text])
    components << build_footer_component(params[:footer_text]) if params[:footer_text].present?
    components << build_buttons_component(params[:buttons]) if params[:buttons].present? && params[:buttons].any?
    components
  end

  def build_header_component(text)
    component = { type: 'HEADER', format: 'TEXT', text: text }
    variables = extract_variables(text)
    component[:example] = { header_text: variables.map { |v| "example_#{v}" } } if variables.any?
    component
  end

  def build_body_component(text)
    component = { type: 'BODY', text: text }
    variables = extract_variables(text)
    component[:example] = { body_text: [variables.map { |v| "example_#{v}" }] } if variables.any?
    component
  end

  def build_footer_component(text)
    { type: 'FOOTER', text: text }
  end

  def build_buttons_component(buttons)
    {
      type: 'BUTTONS',
      buttons: buttons.map { |btn| { type: btn[:type] || 'QUICK_REPLY', text: btn[:text] } }
    }
  end

  def extract_variables(text)
    text.scan(/\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}/).flatten
  end

  def submit_to_meta(request_body)
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def process_response(response, params)
    if response.success?
      {
        success: true,
        template_id: response['id'],
        template_name: params[:name],
        language: params[:language].presence || DEFAULT_LANGUAGE,
        status: TEMPLATE_STATUS_PENDING
      }
    else
      Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
      {
        success: false,
        error: parse_meta_error(response),
        response_code: response.code
      }
    end
  end

  def parse_meta_error(response)
    parsed = JSON.parse(response.body)
    parsed.dig('error', 'message') || 'Template creation failed'
  rescue JSON::ParserError
    'Template creation failed'
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
