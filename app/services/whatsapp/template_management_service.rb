# Manages WhatsApp message templates via the Business API: create, delete, list.
class Whatsapp::TemplateManagementService
  WHATSAPP_API_VERSION = 'v14.0'.freeze
  VALID_CATEGORIES = %w[MARKETING UTILITY AUTHENTICATION].freeze
  VALID_HEADER_FORMATS = %w[TEXT IMAGE VIDEO DOCUMENT].freeze
  VALID_BUTTON_TYPES = %w[PHONE_NUMBER URL QUICK_REPLY COPY_CODE].freeze

  def initialize(whatsapp_channel)
    @whatsapp_channel = whatsapp_channel
  end

  def create(params)
    validate_create_params!(params)
    request_body = build_create_request_body(params)
    Rails.logger.info "[WHATSAPP_TEMPLATES] Creating template: #{request_body.to_json}"
    response = post_template(request_body)
    Rails.logger.info "[WHATSAPP_TEMPLATES] Response: #{response.code} - #{response.body}"
    process_create_response(response, params)
  end

  def delete(template_name)
    raise ArgumentError, 'Template name is required' if template_name.blank?

    response = HTTParty.delete("#{business_account_path}/message_templates?name=#{template_name}", headers: api_headers)
    response.success? ? { success: true } : { success: false, error: parse_error(response) }
  end

  def list
    templates = fetch_all_templates
    { success: true, templates: templates }
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_TEMPLATES] List failed: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def validate_create_params!(params)
    raise ArgumentError, 'Template name is required' if params[:name].blank?
    raise ArgumentError, 'Template category is required' if params[:category].blank?
    raise ArgumentError, "Invalid category: #{params[:category]}" unless VALID_CATEGORIES.include?(params[:category].upcase)
    raise ArgumentError, 'Template language is required' if params[:language].blank?
    raise ArgumentError, 'At least a body component is required' if params[:components].blank?

    validate_components!(params[:components])
  end

  def validate_components!(components)
    validate_body_component!(components)
    validate_header_if_present!(components)
    validate_buttons_if_present!(components)
  end

  def validate_body_component!(components)
    body = components.find { |c| c[:type]&.upcase == 'BODY' }
    raise ArgumentError, 'Body component is required' unless body
    raise ArgumentError, 'Body text is required' if body[:text].blank?
  end

  def validate_header_if_present!(components)
    header = components.find { |c| c[:type]&.upcase == 'HEADER' }
    validate_header!(header) if header
  end

  def validate_buttons_if_present!(components)
    buttons_component = components.find { |c| c[:type]&.upcase == 'BUTTONS' }
    validate_buttons!(buttons_component[:buttons]) if buttons_component&.dig(:buttons)
  end

  def validate_header!(header)
    return if header[:format].blank?
    return if VALID_HEADER_FORMATS.include?(header[:format].upcase)

    raise ArgumentError, "Invalid header format: #{header[:format]}"
  end

  def validate_buttons!(buttons)
    buttons.each do |button|
      next if button[:type].blank?
      next if VALID_BUTTON_TYPES.include?(button[:type].upcase)

      raise ArgumentError, "Invalid button type: #{button[:type]}"
    end
  end

  def build_create_request_body(params)
    body = {
      name: sanitize_template_name(params[:name]),
      language: params[:language],
      category: params[:category].upcase,
      components: build_components(params[:components])
    }
    body[:allow_category_change] = params[:allow_category_change] if params.key?(:allow_category_change)
    body
  end

  def build_components(components)
    components.map { |component| build_single_component(component) }
  end

  def build_single_component(component)
    built = { type: component[:type].upcase }
    populate_component(built, component)
    built
  end

  def populate_component(built, component)
    case built[:type]
    when 'HEADER' then build_header_component(built, component)
    when 'BODY' then build_body_component(built, component)
    when 'FOOTER' then built[:text] = component[:text]
    when 'BUTTONS' then built[:buttons] = build_buttons(component[:buttons]) if component[:buttons]
    end
  end

  def build_body_component(built, component)
    built[:text] = component[:text]
    return if component[:example].blank?

    built[:example] = component[:example].is_a?(Hash) ? component[:example] : { body_text: [Array(component[:example])] }
  end

  def build_header_component(built, component)
    built[:format] = component[:format]&.upcase || 'TEXT'
    if built[:format] == 'TEXT'
      built[:text] = component[:text]
      built[:example] = build_header_example(component) if component[:example].present?
    elsif component[:example].present?
      built[:example] = build_header_example(component)
    end
    built
  end

  def build_header_example(component)
    component[:example].is_a?(Hash) ? component[:example] : { header_handle: Array(component[:example]) }
  end

  def build_buttons(buttons)
    buttons.map { |button| build_single_button(button) }
  end

  def build_single_button(button)
    btn = { type: button[:type].upcase }
    btn[:text] = button[:text] if button[:text].present?
    btn[:phone_number] = button[:phone_number] if btn[:type] == 'PHONE_NUMBER' && button[:phone_number].present?
    btn[:url] = button[:url] if btn[:type] == 'URL' && button[:url].present?
    btn[:example] = button[:example] if button[:example].present?
    btn
  end

  def sanitize_template_name(name)
    name.downcase.gsub(/[^a-z0-9_]/, '_').squeeze('_').gsub(/\A_|_\z/, '')
  end

  def post_template(request_body)
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: request_body.to_json
    )
  end

  def process_create_response(response, params)
    return { success: false, error: parse_error(response) } unless response.success?

    { success: true, template_id: response['id'], template_name: response['name'] || params[:name],
      language: params[:language], category: params[:category], status: response['status'] || 'PENDING' }
  end

  def fetch_all_templates
    url = "#{business_account_path}/message_templates?access_token=#{@whatsapp_channel.provider_config['api_key']}"
    fetch_paginated_templates(url)
  end

  def fetch_paginated_templates(url, accumulated = [])
    response = HTTParty.get(url)
    raise "Failed to fetch templates: #{response.body}" unless response.success?

    data = response['data'] || []
    accumulated.concat(data)

    next_url = response.dig('paging', 'next')
    return accumulated if next_url.blank?

    fetch_paginated_templates(next_url, accumulated)
  end

  def parse_error(response)
    parsed = response.parsed_response
    error = parsed.is_a?(Hash) && parsed['error']
    return "Request failed with status #{response.code}" unless error

    msg = error['error_user_msg'] || error['message'] || 'Unknown error'
    "#{msg} (code: #{error['code']})"
  rescue StandardError
    "Request failed with status #{response.code}"
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
