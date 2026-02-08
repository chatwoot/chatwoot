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

  def send_template(phone_number, template_info)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        template: template_body_parameters(template_info),
        type: 'template'
      }.to_json
    )

    process_response(response)
  end

  def sync_templates
    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = HTTParty.get(url)
    return [] unless response.success?

    next_url = next_url(response)

    return response['data'] + fetch_whatsapp_templates(next_url) if next_url.present?

    response['data']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    response = HTTParty.get("#{business_account_path}/message_templates?access_token=#{whatsapp_channel.provider_config['api_key']}")
    response.success?
  end

  def api_headers
    api_key = whatsapp_channel.provider_config['api_key']
    Rails.logger.info "WhatsApp API Headers: api_key present: #{api_key.present?}"
    { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' }
  end

  def media_url(media_id)
    "#{api_base_path}/v13.0/#{media_id}"
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
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

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        :messaging_product => 'whatsapp',
        :context => whatsapp_reply_context(message),
        'to' => phone_number,
        'type' => type,
        type.to_s => type_content
      }.to_json
    )

    process_response(response)
  end

  def error_message(response)
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    response.parsed_response&.dig('error', 'message')
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

  def whatsapp_reply_context(message)
    reply_to = message.content_attributes[:in_reply_to_external_id]
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
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

    process_response(response)
  end

  # Envia payload interativo completo, pronto do backend (Socialwise Flow)
  def send_interactive_payload(phone_number, message, interactive_payload)
    @message = message
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        interactive: interactive_payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response)
  end

  # Send sticker message using media_id for optimal performance
  def send_sticker_message(phone_number, media_id)
    Rails.logger.info "WhatsApp SendStickerMessage: Sending sticker to #{phone_number} with media_id: #{media_id}"
    
    payload = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone_number,
      type: 'sticker',
      sticker: {
        id: media_id
      }
    }
    
    Rails.logger.info "WhatsApp SendStickerMessage: Payload: #{payload.to_json}"
    Rails.logger.info "WhatsApp SendStickerMessage: URL: #{phone_id_path}/messages"
    
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: payload.to_json
    )
    
    Rails.logger.info "WhatsApp SendStickerMessage: Response status: #{response.code}"
    Rails.logger.info "WhatsApp SendStickerMessage: Response body: #{response.body}"

    process_response(response)
  end

  # Upload media to WhatsApp Cloud API and return media_id
  def upload_media(media_data, content_type = 'image/webp')
    Rails.logger.info "WhatsApp UploadMedia: Starting upload, size: #{media_data.bytesize} bytes, type: #{content_type}"
    
    # Create a temporary file for the upload
    temp_file = Tempfile.new(['sticker', '.webp'])
    temp_file.binmode # CRITICAL: Ensure binary mode
    
    # CRITICAL FIX: Ensure media_data is in binary encoding
    binary_data = media_data.force_encoding('BINARY')
    temp_file.write(binary_data)
    temp_file.rewind

    begin
      Rails.logger.info "WhatsApp UploadMedia: Uploading to #{phone_id_path}/media"
      Rails.logger.info "WhatsApp UploadMedia: Temp file size: #{temp_file.size} bytes"
      
      response = HTTParty.post(
        "#{phone_id_path}/media",
        headers: {
          'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}"
        },
        multipart: true,
        body: {
          messaging_product: 'whatsapp',
          file: temp_file,
          type: content_type
        }
      )

      Rails.logger.info "WhatsApp UploadMedia: Response status: #{response.code}"
      Rails.logger.info "WhatsApp UploadMedia: Response body: #{response.body}"

      if response.success? && response.parsed_response['id'].present?
        media_id = response.parsed_response['id']
        Rails.logger.info "WhatsApp UploadMedia: Success! Media ID: #{media_id}"
        media_id
      else
        error_details = response.parsed_response&.dig('error') || response.body
        Rails.logger.error "WhatsApp UploadMedia: Upload failed - Status: #{response.code}, Error: #{error_details}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "WhatsApp UploadMedia: Exception during upload: #{e.message}"
      Rails.logger.error "WhatsApp UploadMedia: Backtrace: #{e.backtrace.first(3).join("\n")}"
      nil
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

end
