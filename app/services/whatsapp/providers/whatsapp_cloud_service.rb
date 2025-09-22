class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

<<<<<<< HEAD
  def send_template(phone_number, template_info, message)
    template_body = template_body_parameters(template_info)

    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual', # Only individual messages supported (not group messages)
      to: phone_number,
      type: 'template',
      template: template_body
    }

    response = safe_http_request('whatsapp_cloud_send_template') do
      HTTParty.post(
        "#{phone_id_path}/messages",
        headers: api_headers,
        body: request_body.to_json
      )
    end

    process_response(response, message)
  end

  def sync_templates
    # ensuring that channels with wrong provider config wouldn't keep trying to sync templates
    whatsapp_channel.mark_message_templates_updated
    api_key = provider_config_object.api_key
    templates = fetch_whatsapp_templates("#{business_account_path}/message_templates?access_token=#{api_key}")
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if templates.present?
  end

  def fetch_whatsapp_templates(url)
    response = safe_http_request('whatsapp_cloud_fetch_templates') do
      HTTParty.get(url)
    end
    return [] unless response.success?

    next_url = next_url(response)

    return response['data'] + fetch_whatsapp_templates(next_url) if next_url.present?

    response['data']
  end

  def next_url(response)
    response['paging'] ? response['paging']['next'] : ''
  end

  def validate_provider_config?
    provider_config_object.validate_config?
  end

  def api_headers
    api_key = provider_config_object.api_key
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
    phone_number_id = provider_config_object.phone_number_id
    "#{api_base_path}/v13.0/#{phone_number_id}"
  end

  def business_account_path
    business_account_id = provider_config_object.business_account_id
    "#{api_base_path}/v14.0/#{business_account_id}"
  end

  def send_text_message(phone_number, message)
    response = safe_http_request('whatsapp_cloud_send_text') do
      HTTParty.post(
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
    end

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = message.outgoing_content unless %w[audio sticker].include?(type)
    type_content['filename'] = attachment.file.filename if type == 'document'
    response = safe_http_request('whatsapp_cloud_send_attachment') do
      HTTParty.post(
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
    end

    process_response(response, message)
  end

  def error_message(response)
    # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/#sample-response
    response.parsed_response&.dig('error', 'message')
  end

  def template_body_parameters(template_info)
    template_body = {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      }
    }

    # Enhanced template parameters structure
    # Note: Legacy format support (simple parameter arrays) has been removed
    # in favor of the enhanced component-based structure that supports
    # headers, buttons, and authentication templates.
    #
    # Expected payload format from frontend:
    # {
    #   processed_params: {
    #     body: { '1': 'John', '2': '123 Main St' },
    #     header: { media_url: 'https://...', media_type: 'image' },
    #     buttons: [{ type: 'url', parameter: 'otp123456' }]
    #   }
    # }
    # This gets transformed into WhatsApp API component format:
    # [
    #   { type: 'body', parameters: [...] },
    #   { type: 'header', parameters: [...] },
    #   { type: 'button', sub_type: 'url', parameters: [...] }
    # ]
    template_body[:components] = template_info[:parameters] || []

    template_body
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

    response = safe_http_request('whatsapp_cloud_send_interactive') do
      HTTParty.post(
        "#{phone_id_path}/messages",
        headers: api_headers,
        body: {
          messaging_product: 'whatsapp',
          to: phone_number,
          interactive: payload,
          type: 'interactive'
        }.to_json
      )
    end

    process_response(response, message)
  end
end
