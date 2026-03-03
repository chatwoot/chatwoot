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

  # --- WhatsApp Cloud API: Mark as Read ---
  # Marks a message as read (sends blue double-check to the user).
  def mark_as_read(message_id)
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        status: 'read',
        message_id: message_id
      }.to_json
    )
    Rails.logger.debug { "[WHATSAPP] Mark as read for #{message_id}: #{response.code}" }
    response.success?
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP] Failed to mark as read: #{e.message}"
    false
  end

  # --- WhatsApp Cloud API: Typing Indicator ---
  # Shows a typing bubble ("digitando...") in the WhatsApp client.
  # Also marks the message as read. Requires API v21.0+.
  # The indicator auto-dismisses after 25 seconds or when you send a reply.
  def send_typing_indicator(message_id)
    url = "#{modern_phone_id_path}/messages"
    payload = {
      messaging_product: 'whatsapp',
      status: 'read',
      message_id: message_id,
      typing_indicator: { type: 'text' }
    }
    Rails.logger.info "[WHATSAPP] Sending typing indicator for #{message_id} to #{url}"
    response = HTTParty.post(url, headers: api_headers, body: payload.to_json)
    Rails.logger.info "[WHATSAPP] Typing indicator response: #{response.code} — #{response.body}"
    response.success?
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP] Failed to send typing indicator: #{e.class} — #{e.message}"
    false
  end

  # Reacts to a message with an emoji. Pass empty emoji to remove.
  def send_reaction(phone_number, message_id, emoji)
    response = post_message(reaction_payload(phone_number, message_id, emoji))
    log_result('Reaction', response)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP] Failed to send reaction: #{e.message}"
    false
  end

  # Sends a message with up to 3 reply buttons.
  def send_button_message(phone_number, body_text, buttons, header: nil, footer: nil)
    interactive = build_button_interactive(body_text, buttons, header: header, footer: footer)
    post_interactive_message(phone_number, interactive)
  end

  # Sends a message with a list of options (up to 10 rows).
  # options: { header:, footer: } optional
  def send_list_message(phone_number, body_text, button_text, sections, **)
    interactive = build_list_interactive(body_text, button_text, sections, **)
    post_interactive_message(phone_number, interactive)
  end

  def send_template(phone_number, template_info, message)
    template_body = template_body_parameters(template_info)

    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: 'individual', # Only individual messages supported (not group messages)
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

  def csat_template_service
    @csat_template_service ||= Whatsapp::CsatTemplateService.new(whatsapp_channel)
  end

  def api_base_path
    ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  # Modern API path (v21.0+) for features like typing indicators that require newer versions.
  def modern_phone_id_path
    "#{api_base_path}/v21.0/#{whatsapp_channel.provider_config['phone_number_id']}"
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
    #     header: {
    #       media_url: 'https://...',
    #       media_type: 'image',
    #       media_name: 'filename.pdf' # Optional, for document templates only
    #     },
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

  def post_message(payload)
    HTTParty.post("#{phone_id_path}/messages", headers: api_headers, body: payload.to_json)
  end

  def reaction_payload(phone_number, message_id, emoji)
    { messaging_product: 'whatsapp', recipient_type: 'individual',
      to: phone_number, type: 'reaction',
      reaction: { message_id: message_id, emoji: emoji } }
  end

  def log_result(label, response)
    if response.success?
      Rails.logger.info { "[WHATSAPP] #{label} sent successfully" }
    else
      Rails.logger.warn "[WHATSAPP] Failed to send #{label.downcase}: #{response.body}"
    end
    response.success?
  end

  def build_button_interactive(body_text, buttons, header: nil, footer: nil)
    reply_buttons = buttons.first(3).map do |btn|
      { type: 'reply', reply: { id: btn[:id] || btn['id'], title: btn[:title] || btn['title'] } }
    end
    interactive = { type: 'button', body: { text: body_text }, action: { buttons: reply_buttons } }
    apply_header_footer(interactive, header, footer)
  end

  def build_list_interactive(body_text, button_text, sections, header: nil, footer: nil)
    interactive = { type: 'list', body: { text: body_text }, action: { button: button_text, sections: sections } }
    apply_header_footer(interactive, header, footer)
  end

  def apply_header_footer(interactive, header, footer)
    interactive[:header] = { type: 'text', text: header } if header.present?
    interactive[:footer] = { text: footer } if footer.present?
    interactive
  end

  # Sends a WhatsApp Flow message to the user.
  # flow_id:     Meta Flow ID
  # flow_cta:    Button text (e.g. "Book Appointment")
  # body_text:   Message body
  # screen:      Initial screen to show (default: first screen)
  # flow_action: "navigate" (show specific screen) or "data_exchange"
  # data:        Initial data to pass to the flow
  def send_flow_message(phone_number, flow_params)
    action_payload = {
      name: 'flow',
      parameters: {
        flow_message_version: '3',
        flow_token: SecureRandom.uuid,
        flow_id: flow_params[:flow_id],
        flow_cta: flow_params[:flow_cta],
        flow_action: flow_params[:flow_action] || 'navigate'
      }
    }

    if flow_params[:screen].present?
      action_payload[:parameters][:flow_action_payload] = {
        screen: flow_params[:screen], data: flow_params[:data] || {}
      }
    end

    interactive = { type: 'flow', body: { text: flow_params[:body_text] }, action: action_payload }
    interactive = apply_header_footer(interactive, flow_params[:header], flow_params[:footer])

    post_interactive_message(phone_number, interactive)
  end

  def post_interactive_message(phone_number, interactive)
    response = post_message(
      messaging_product: 'whatsapp', recipient_type: 'individual',
      to: phone_number, type: 'interactive', interactive: interactive
    )
    return response.parsed_response.dig('messages', 0, 'id') if response.success?

    Rails.logger.warn "[WHATSAPP] Failed to send interactive message: #{response.body}"
    nil
  end
end
