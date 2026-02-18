# YCloud WhatsApp Business API Provider
# https://docs.ycloud.com/reference/introduction
# API Base: https://api.ycloud.com/v2
# Auth: X-API-Key header
class Whatsapp::Providers::WhatsappYcloudService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    @message = message
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'template',
        template: template_body_parameters(template_info)
      }.to_json
    )

    process_response(response)
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_templates
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def validate_provider_config?
    response = HTTParty.get(
      "#{api_base_path}/whatsapp/templates?limit=1",
      headers: api_headers
    )
    response.success?
  end

  def api_headers
    { 'X-API-Key' => whatsapp_channel.provider_config['api_key'], 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    "#{api_base_path}/whatsapp/media/download/#{media_id}"
  end

  private

  def api_base_path
    ENV.fetch('YCLOUD_BASE_URL', 'https://api.ycloud.com/v2')
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: { body: message.content }
      }.to_json
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'

    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        'from' => whatsapp_channel.phone_number,
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response)
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'interactive',
        interactive: payload
      }.to_json
    )

    process_response(response)
  end

  def error_message(response)
    response.parsed_response&.dig('errorMessage') || response.parsed_response&.dig('message')
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      },
      components: [{
        type: 'body',
        parameters: template_info[:parameters]
      }]
    }
  end

  def fetch_templates(page = 1, accumulated_templates = [])
    response = HTTParty.get(
      "#{api_base_path}/whatsapp/templates?page=#{page}&limit=100",
      headers: api_headers
    )
    return accumulated_templates unless response.success?

    items = response.parsed_response['items'] || []
    accumulated_templates.concat(normalize_templates(items))

    total = response.parsed_response['total'] || 0
    return accumulated_templates if accumulated_templates.length >= total || items.empty?

    fetch_templates(page + 1, accumulated_templates)
  end

  def normalize_templates(items)
    items.map do |template|
      {
        'name' => template['name'],
        'status' => template['status']&.downcase,
        'language' => template['language'],
        'category' => template['category'],
        'namespace' => template['wabaId'],
        'components' => template['components'] || []
      }
    end
  end

  def process_response(response)
    parsed_response = response.parsed_response
    if response.success? && parsed_response['id'].present?
      parsed_response['id']
    else
      handle_error(response)
      nil
    end
  end
end
