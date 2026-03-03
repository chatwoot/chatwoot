class Whatsapp::TemplateCreationService
  def initialize(message_template:, inbox:)
    @message_template = message_template
    @inbox = inbox
    @whatsapp_channel = inbox.channel
    @api_version = GlobalConfigService.load('WHATSAPP_API_VERSION', 'v22.0')
  end

  def perform
    response = submit_to_meta
    process_response(response)
  end

  private

  def submit_to_meta
    HTTParty.post(
      "#{business_account_path}/message_templates",
      headers: api_headers,
      body: build_request_body.to_json
    )
  end

  def build_request_body
    {
      name: @message_template.name,
      language: @message_template.language,
      category: @message_template.category.upcase,
      components: build_components
    }
  end

  def build_components
    @message_template.components.map do |component|
      comp = component.deep_dup
      # Ensure types are uppercase for Meta API
      comp['type'] = comp['type'].to_s.upcase
      process_component(comp)
    end
  end

  def process_component(component)
    case component['type']
    when 'HEADER'
      process_header(component)
    when 'BUTTONS'
      process_buttons(component)
    else
      component
    end
  end

  def process_header(component)
    format = component['format'].to_s.upcase
    component['format'] = format
    component.delete('media') unless media_header_with_blob?(component, format)

    return apply_header_handle_from_upload(component) if media_header_with_blob?(component, format)
    return apply_header_handle_from_example(component) if media_header_with_example?(component, format)

    component
  end

  def media_header_with_blob?(component, format = nil)
    format ||= component['format'].to_s.upcase
    %w[IMAGE VIDEO DOCUMENT].include?(format) && component.dig('media', 'blob_id').present?
  end

  def media_header_with_example?(component, format = nil)
    format ||= component['format'].to_s.upcase
    %w[IMAGE VIDEO DOCUMENT].include?(format) && component['example'].present?
  end

  def apply_header_handle_from_upload(component)
    handle = Whatsapp::FacebookUploadService.new(
      blob_signed_id: component['media']['blob_id'],
      whatsapp_channel: @whatsapp_channel
    ).perform
    component.delete('media')
    component['example'] = { 'header_handle' => [handle] } if handle.present?
    component
  end

  def apply_header_handle_from_example(component)
    handle = component.dig('example', 'header_handle')&.first
    component['example'] = { 'header_handle' => [handle] } if handle.present?
    component
  end

  def process_buttons(component)
    return component unless component['buttons'].is_a?(Array)

    component['buttons'] = component['buttons'].map do |button|
      button['type'] = button['type'].to_s.upcase
      process_flow_button(button)
    end
    component
  end

  # Ensure FLOW buttons have correct Meta API format
  def process_flow_button(button)
    return button unless button['type'] == 'FLOW'

    # Meta requires: flow_id, flow_action (navigate/data_exchange), navigate_screen (optional)
    button['flow_id'] = button.delete('flowId') || button['flow_id']
    button['flow_action'] = (button.delete('flowAction') || button['flow_action'] || 'navigate').upcase
    navigate_screen = button.delete('navigateScreen') || button['navigate_screen']
    button['navigate_screen'] = navigate_screen if navigate_screen.present?
    button
  end

  def process_response(response)
    if response.success?
      update_template_after_submission(response)
      { success: true, template: @message_template }
    else
      error_message = parse_error(response)
      Rails.logger.error "WhatsApp template creation failed: #{response.code} - #{response.body}"
      { success: false, error: error_message }
    end
  end

  def update_template_after_submission(response)
    @message_template.update!(
      platform_template_id: response['id'],
      status: :pending
    )
  end

  def parse_error(response)
    parsed = response.parsed_response
    if parsed.is_a?(Hash) && parsed['error']
      parsed['error']['message'] || 'Template creation failed'
    else
      'Template creation failed'
    end
  rescue StandardError
    'Template creation failed'
  end

  def business_account_path
    "#{api_base_path}/#{@api_version}/#{@whatsapp_channel.provider_config['business_account_id']}"
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
