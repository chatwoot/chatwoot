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

  # Async send: enqueues the message for delivery instead of sending synchronously.
  # Returns an enqueue ID; actual delivery is confirmed via webhook status update.
  def send_message_async(phone_number, message)
    @message = message
    type_payload = build_message_payload(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/send",
      headers: api_headers,
      body: type_payload.to_json
    )
    process_response(response)
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
    return false unless response.success?

    register_webhook
    true
  end

  def api_headers
    { 'X-API-Key' => whatsapp_channel.provider_config['api_key'], 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    "#{api_base_path}/whatsapp/media/download/#{media_id}"
  end

  # Mark a message as read (sends blue checkmarks to the customer).
  # @param message_id [String] The WhatsApp message ID (wamid)
  def mark_as_read(message_id)
    HTTParty.post(
      "#{api_base_path}/whatsapp/messages/markAsRead",
      headers: api_headers,
      body: { messageId: message_id, to: whatsapp_channel.phone_number }.to_json
    )
  end

  # Send a typing indicator to the customer.
  # The indicator auto-expires after ~25 seconds.
  # @param phone_number [String] The customer phone number
  def send_typing_indicator(phone_number)
    HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'typing'
      }.to_json
    )
  end

  # Upload media to YCloud for use in messages.
  # @param file [File/IO] The file to upload
  # @param content_type [String] MIME type
  # @return [String, nil] The media ID on success
  def upload_media(file, content_type)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/media/upload",
      headers: { 'X-API-Key' => whatsapp_channel.provider_config['api_key'] },
      multipart: true,
      body: { file: file, content_type: content_type }
    )
    response.parsed_response&.dig('id') if response.success?
  end

  # Convenience accessors for YCloud sub-services.
  def template_service
    @template_service ||= Whatsapp::Ycloud::TemplateService.new(whatsapp_channel: whatsapp_channel)
  end

  def flow_service
    @flow_service ||= Whatsapp::Ycloud::FlowService.new(whatsapp_channel: whatsapp_channel)
  end

  def call_service
    @call_service ||= Whatsapp::Ycloud::CallService.new(whatsapp_channel: whatsapp_channel)
  end

  def profile_service
    @profile_service ||= Whatsapp::Ycloud::ProfileService.new(whatsapp_channel: whatsapp_channel)
  end

  def contact_service
    @contact_service ||= Whatsapp::Ycloud::ContactService.new(whatsapp_channel: whatsapp_channel)
  end

  def event_service
    @event_service ||= Whatsapp::Ycloud::EventService.new(whatsapp_channel: whatsapp_channel)
  end

  def multi_channel_service
    @multi_channel_service ||= Whatsapp::Ycloud::MultiChannelService.new(whatsapp_channel: whatsapp_channel)
  end

  def unsubscriber_service
    @unsubscriber_service ||= Whatsapp::Ycloud::UnsubscriberService.new(whatsapp_channel: whatsapp_channel)
  end

  def webhook_service
    @webhook_service ||= Whatsapp::Ycloud::WebhookService.new(whatsapp_channel: whatsapp_channel)
  end

  def account_service
    @account_service ||= Whatsapp::Ycloud::AccountService.new(whatsapp_channel: whatsapp_channel)
  end

  private

  def api_base_path
    ENV.fetch('YCLOUD_BASE_URL', 'https://api.ycloud.com/v2')
  end

  def build_message_payload(phone_number, message)
    if message.attachments.present?
      build_attachment_payload(phone_number, message)
    elsif message.content_type == 'input_select'
      build_interactive_payload(phone_number, message)
    else
      {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: { body: message.content },
        context: whatsapp_reply_context(message)
      }.compact
    end
  end

  def build_attachment_payload(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = { 'link': attachment.download_url }
    type_content['caption'] = message.content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    {
      'from' => whatsapp_channel.phone_number,
      'to' => phone_number,
      'type' => type,
      'context' => whatsapp_reply_context(message),
      type.to_s => type_content
    }.compact
  end

  def build_interactive_payload(phone_number, message)
    {
      from: whatsapp_channel.phone_number,
      to: phone_number,
      type: 'interactive',
      interactive: create_payload_based_on_items(message),
      context: whatsapp_reply_context(message)
    }.compact
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: {
        from: whatsapp_channel.phone_number,
        to: phone_number,
        type: 'text',
        text: { body: message.content },
        context: whatsapp_reply_context(message)
      }.compact.to_json
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: build_attachment_payload(phone_number, message).to_json
    )

    process_response(response)
  end

  def send_interactive_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/whatsapp/messages/sendDirectly",
      headers: api_headers,
      body: build_interactive_payload(phone_number, message).to_json
    )

    process_response(response)
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    { message_id: reply_to }
  end

  def register_webhook
    webhook_url = "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/whatsapp/#{whatsapp_channel.phone_number}"
    HTTParty.post(
      "#{api_base_path}/webhookEndpoints",
      headers: api_headers,
      body: {
        url: webhook_url,
        events: Whatsapp::Ycloud::WebhookService::ALL_EVENTS,
        status: 'active'
      }.to_json
    )
  rescue StandardError => e
    Rails.logger.warn "YCloud webhook registration failed: #{e.message}"
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
