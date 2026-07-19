# frozen_string_literal: true

class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
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

  def send_template(phone_number, template_info, message)
    template_body = template_body_parameters(template_info)

    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone_number,
      type: 'template',
      template: template_body
    }

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: request_body.to_json
    )

    process_response(response, message)
  end

  def sync_templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url)
    unless response.success?
      Rails.logger.warn "[WHATSAPP] Template sync failed for account #{whatsapp_channel.account_id} " \
                        "inbox #{whatsapp_channel.inbox&.id}: #{response.code} #{error_message(response)}"
      return []
    end

    next_url = next_url(response)
    return response['data'] + fetch_whatsapp_templates(next_url) if next_url.present?

    response['data']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    config = whatsapp_channel.provider_config
    response = HTTParty.get("#{business_account_path}/message_templates?access_token=#{config['api_key']}")
    return log_transfer_failure('waba_or_token_check', response) unless response.success?

    return true unless whatsapp_channel.provider_config_changed?

    phone_response = HTTParty.get("#{business_account_path}/phone_numbers?fields=id&limit=100&access_token=#{config['api_key']}")
    ids = phone_response.parsed_response.is_a?(Hash) ? Array(phone_response.parsed_response['data']) : []
    return true if phone_response.success? && ids.any? { |number| number['id'] == config['phone_number_id'].to_s }

    log_transfer_failure('phone_number_id_check', phone_response)
  end

  def api_headers
    { 'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  def create_csat_template(template_config)
    csat_template_service.create_template(template_config)
  end

  def delete_csat_template(template_name = nil)
    template_name ||= CsatTemplateNameService.csat_template_name(whatsapp_channel.inbox.id)
    csat_template_service.delete_template(template_name)
  end

  def get_template_status(template_name)
    csat_template_service.get_template_status(template_name)
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  private

  def log_transfer_failure(check, response)
    return false unless whatsapp_channel.embedded_to_manual_transfer_pending?

    error_message = response.parsed_response.is_a?(Hash) ? response.parsed_response.dig('error', 'message') : nil
    Rails.logger.warn("[WHATSAPP_EMBEDDED_TO_MANUAL] failure account_id=#{whatsapp_channel.account_id} channel_id=#{whatsapp_channel.id} " \
                      "check=#{check} http_status=#{response.code} meta_error=#{error_message}")
    false
  end

  def csat_template_service
    @csat_template_service ||= Whatsapp::CsatTemplateService.new(whatsapp_channel)
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  def phone_id_path(version = 'v13.0')
    "#{api_base_path}/#{version}/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        context: whatsapp_reply_context(message),
        to: phone_number,
        text: { body: message.outgoing_content },
        type: 'text'
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    normalize_opus_content_type(attachment)
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = build_attachment_content(type, attachment, message)
    response = HTTParty.post(
      "#{phone_id_path('v24.0')}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response, message)
  end

  def error_message(response)
    response.parsed_response.dig('error', 'message') if response.parsed_response.is_a?(Hash)
  end

  def voice_message?(type, attachment)
    type == 'audio' && attachment.meta&.dig('is_voice_message') && attachment.file.content_type == 'audio/ogg'
  end

  def normalize_opus_content_type(attachment)
    return unless attachment.file.attached?

    blob = attachment.file.blob
    return unless blob.content_type == 'audio/opus'

    return if blob.update(content_type: 'audio/ogg')

    Rails.logger.error("Failed to normalize blob #{blob.id} content_type from audio/opus to audio/ogg")
  end

  # Builds the attachment content hash for the WhatsApp API payload.
  #
  # When WHATSAPP_MEDIA_UPLOAD_STRATEGY=direct (default), the file is uploaded
  # to the WhatsApp media endpoint first, and the returned media_id is sent.
  # This bypasses Meta's fwdproxy, which is rate-limited per destination ASN
  # and causes intermittent 131053 errors on shared-ASN hosting providers.
  #
  # When WHATSAPP_MEDIA_UPLOAD_STRATEGY=link, the legacy URL-based approach is
  # used (sends link: attachment.download_url). Use this as a fallback only.
  def build_attachment_content(type, attachment, message)
    type_content = if direct_upload_strategy?
                     upload_and_build_media_id_content(attachment)
                   else
                     { 'link' => attachment.download_url }
                   end

    type_content['caption'] = message.outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename.to_s if type == 'document'
    type_content['voice'] = true if voice_message?(type, attachment)
    type_content
  end

  def direct_upload_strategy?
    ENV.fetch('WHATSAPP_MEDIA_UPLOAD_STRATEGY', 'direct') == 'direct'
  end

  def upload_and_build_media_id_content(attachment)
    media_id = Whatsapp::MediaUploadService.new(
      channel: whatsapp_channel,
      attachment: attachment
    ).upload
    { 'id' => media_id }
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP] Direct media upload failed, falling back to link for attachment #{attachment.id}: #{e.message}")
    { 'link' => attachment.download_url }
  end

  def template_body_parameters(template_info)
    template_body = {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      }
    }

    template_body[:components] = template_info[:parameters] || []
    template_body
  end

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    { message_id: reply_to }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end
end

Whatsapp::Providers::WhatsappCloudService.prepend_mod_with('Whatsapp::Providers::WhatsappCloudService')
