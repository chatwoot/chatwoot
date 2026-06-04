class Whatsapp::Providers::WhatsappCloudService < Whatsapp::Providers::BaseService
  GROUP_CONTACT_MENTION_PATTERN = %r{\[@([^\]]+)\]\(mention://group[_-]contact/(\d+)/[^)]+\)|mention://group[_-]contact/(\d+)/([^\s)]+)}

  def send_message(phone_number, message)
    @message = message

    if message.content_type == 'sticker'
      send_sticker_message(phone_number, message)
    elsif contact_message?(message)
      send_contacts_message(phone_number, message)
    elsif message.attachments.present?
      send_attachments(phone_number, message)
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
      recipient_type: recipient_type_for(message),
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

  def send_reaction(phone_number, message_id, emoji)
    response = HTTParty.post(
      messages_path,
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        type: 'reaction',
        reaction: {
          message_id: message_id,
          emoji: emoji
        }
      }.to_json
    )

    response.success? && response.parsed_response['error'].blank?
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

  def send_message_update(message)
    payload = message_update_payload(message)
    return false if payload[:message_id].blank? || payload[:recipient_id].blank?

    response = HTTParty.public_send(
      message_update_http_method,
      message_path(message),
      headers: api_headers,
      body: payload.to_json
    )

    response.success? && response.parsed_response['error'].blank?
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] message update failed: #{e.class}: #{e.message}")
    false
  end

  def message_update_payload(message)
    payload = {
      messaging_product: 'whatsapp',
      status: message[:status],
      message_id: message[:source_id],
      recipient_id: message_update_recipient_id(message),
      recipient_type: 'individual'
    }
    if message[:conversation][:group] && message[:conversation][:group_source_id].present?
      return payload.merge(
        recipient_id: message[:conversation][:group_source_id],
        recipient_type: 'group'
      )
    end
    payload
  end

  def message_update_http_method
    :post
  end

  def message_path(_message)
    messages_path
  end

  private

  def message_update_recipient_id(message)
    (message[:sender] || {})[:phone_number].presence ||
      contact_inbox_source_id(message[:conversation]&.[](:contact_inbox))
  end

  def contact_inbox_source_id(contact_inbox)
    return if contact_inbox.blank?
    return contact_inbox[:source_id] if contact_inbox.respond_to?(:[]) && contact_inbox[:source_id].present?
    return contact_inbox['source_id'] if contact_inbox.respond_to?(:[]) && contact_inbox['source_id'].present?
    return contact_inbox.source_id if contact_inbox.respond_to?(:source_id)
  end

  def recipient_type_for(message)
    message.conversation.group? ? 'group' : 'individual'
  end

  def api_base_path
    whatsapp_channel.provider_config['url'] || ENV.fetch('WHATSAPP_CLOUD_BASE_URL', 'https://graph.facebook.com')
  end

  # TODO: See if we can unify the API versions and for both paths and make it consistent with out facebook app API versions
  def phone_id_path
    "#{api_base_path}/v13.0/#{whatsapp_channel.provider_config['phone_number_id']}"
  end

  def messages_path
    "#{phone_id_path}/messages"
  end

  def business_account_path
    "#{api_base_path}/v14.0/#{whatsapp_channel.provider_config['business_account_id']}"
  end

  def csat_template_service
    @csat_template_service ||= Whatsapp::CsatTemplateService.new(whatsapp_channel)
  end

  def send_attachments(phone_number, message)
    attachments = message.attachments
    last_message_id = nil

    attachments.each_with_index do |attachment, index|
      include_caption = index.zero?
      last_message_id = send_attachment_message(
        phone_number,
        message,
        attachment,
        include_caption: include_caption
      )
    end

    last_message_id
  end

  def send_text_message(phone_number, message)
    mention_ids = whatsapp_mention_ids(message)
    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: recipient_type_for(message),
      context: whatsapp_reply_context(message),
      to: phone_number,
      text: { body: format_content(message) },
      type: 'text'
    }
    request_body[:mentions] = mention_ids if mention_ids.present?

    response = HTTParty.post(
      messages_path,
      headers: api_headers,
      body: request_body.to_json
    )

    process_response(response, message)
  end

  def format_content(message)
    normalized_content = whatsapp_outgoing_content(message)&.rstrip
    return normalized_content unless should_prefix_sender_name?(message)

    message.sender_name.present? ? "*#{message.sender_name}*: #{normalized_content}" : normalized_content
  end

  def whatsapp_outgoing_content(message)
    return message.outgoing_content unless message.conversation.group? && whatsapp_group_mentions(message).present?

    content = replace_group_mentions(message.content.to_s, message)
    Messages::MarkdownRendererService.new(
      content,
      message.conversation.inbox.channel_type,
      whatsapp_channel
    ).render
  end

  def should_prefix_sender_name?(message)
    return true if message.conversation.group?

    feature = whatsapp_channel.inbox.account.feature_enabled?('send_agent_name_in_whatsapp_message')
    config = whatsapp_channel.provider_config['send_agent_name']
    feature || config
  end

  def send_attachment_message(phone_number, message, attachment, include_caption: true)
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    type_content = {
      'link': attachment.download_url
    }
    type_content['caption'] = whatsapp_outgoing_content(message) unless %w[audio sticker].include?(type) || !include_caption
    mention_ids = whatsapp_mention_ids(message)
    type_content['mentions'] = mention_ids if mention_ids.present?
    type_content['filename'] = attachment.file.filename if type == 'document'
    request_body = {
      :messaging_product => 'whatsapp',
      :recipient_type => recipient_type_for(message),
      :context => whatsapp_reply_context(message),
      'to' => phone_number,
      'type' => type,
      type.to_s => type_content
    }
    request_body[:mentions] = mention_ids if mention_ids.present?

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: request_body.to_json
    )

    process_response(response, message)
  end

  def send_sticker_message(phone_number, message)
    sticker_url = message.content_attributes&.[]('sticker_url')
    if sticker_url.blank?
      Rails.logger.warn("[WHATSAPP] Sticker url missing message_id=#{message.id}")
      return
    end

    Rails.logger.info("[WHATSAPP] Sending sticker message_id=#{message.id} to=#{phone_number}")
    Rails.logger.info("[WHATSAPP] Sticker payload message_id=#{message.id} payload=#{{
      messaging_product: 'whatsapp',
      context: whatsapp_reply_context(message),
      to: phone_number,
      type: 'sticker',
      sticker: {
        link: sticker_url
      }
    }.to_json}")
    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        recipient_type: recipient_type_for(message),
        context: whatsapp_reply_context(message),
        to: phone_number,
        type: 'sticker',
        sticker: {
          link: sticker_url
        }
      }.to_json
    )

    process_response(response, message)
  end

  def send_contacts_message(phone_number, message)
    contacts_payload = whatsapp_contacts_payload(message)
    request_body = {
      messaging_product: 'whatsapp',
      recipient_type: recipient_type_for(message),
      context: whatsapp_reply_context(message),
      to: phone_number,
      type: 'contacts',
      contacts: contacts_payload
    }

    Rails.logger.info(
      "[WHATSAPP] Sending contacts message_id=#{message.id} to=#{phone_number} payload=#{request_body.to_json}"
    )

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: request_body.to_json
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
    if reply_to.blank?
      in_reply_to_id = message.content_attributes[:in_reply_to]
      reply_to = message.conversation.messages.find_by(id: in_reply_to_id)&.source_id if in_reply_to_id.present?
    end
    return nil if reply_to.blank?

    {
      message_id: reply_to
    }
  end

  def replace_group_mentions(content, message)
    mentions_by_contact_id = whatsapp_group_mentions(message).index_by { |mention| mention[:mention_id].to_s }

    content.gsub(GROUP_CONTACT_MENTION_PATTERN) do
      contact_id = Regexp.last_match(2) || Regexp.last_match(3)
      mention = mentions_by_contact_id[contact_id]
      display_identifier = mention&.dig(:bsuid).to_s.delete_prefix('@').delete_suffix('@lid')

      display_identifier.present? ? "@#{display_identifier}" : Regexp.last_match(0)
    end
  end

  def whatsapp_mention_ids(message)
    whatsapp_group_mentions(message).filter_map { |mention| mention[:bsuid].presence }
  end

  def whatsapp_group_mentions(message)
    return [] unless message.conversation.group?
    return [] unless whatsapp_channel.provider == 'unoapi'

    mentions = group_mentions_from_content_attributes(message) + group_mentions_from_content(message)
    mentions.uniq { |mention| [mention[:mention_id].to_s, mention[:bsuid].to_s] }
  end

  def group_mentions_from_content_attributes(message)
    mentions = message.content_attributes&.[]('group_mentions') || []
    mentions.filter_map do |mention|
      mention = mention.with_indifferent_access
      bsuid = mention[:bsuid].to_s.delete_prefix('@').presence || mention[:phone_number].to_s.gsub(/\D/, '').presence
      contact_id = mention[:contact_id].presence
      next if bsuid.blank? || contact_id.blank?

      { mention_id: contact_id, contact_id: contact_id, bsuid: bsuid }
    end
  end

  def group_mentions_from_content(message)
    message.content.to_s.scan(GROUP_CONTACT_MENTION_PATTERN).filter_map do |match|
      mention_id = (match[1] || match[2]).presence
      next if mention_id.blank?

      group_mention_from_id(message, mention_id)
    end
  end

  def group_mention_from_id(message, mention_id)
    group_contact = message.conversation.group_contacts.includes(:contact).find_by(contact_id: mention_id) ||
                    message.conversation.group_contacts.includes(:contact).find_by(id: mention_id)
    contact = group_contact&.contact || Contact.find_by(id: mention_id, account_id: message.account_id)
    bsuid = group_mention_identifier(contact, group_contact)
    return if contact.blank? || bsuid.blank?

    { mention_id: mention_id, contact_id: contact.id, bsuid: bsuid }
  end

  def group_mention_identifier(contact, group_contact)
    metadata = group_contact&.metadata || {}
    contact&.bsuid.presence ||
      metadata['user_id'].presence ||
      metadata['lid'].presence ||
      (metadata['jid'].to_s.end_with?('@lid') ? metadata['jid'] : nil) ||
      contact&.phone_number.to_s.gsub(/\D/, '').presence ||
      metadata['wa_id'].to_s.gsub(/\D/, '').presence
  end

  def contact_message?(message)
    message.attachments.any?(&:contact?)
  end

  def whatsapp_contacts_payload(message)
    message.attachments.select(&:contact?).map do |attachment|
      meta = attachment.meta&.with_indifferent_access || {}
      formatted_name = meta[:formatted_name].presence ||
                       [meta[:first_name], meta[:last_name]].compact.join(' ').presence ||
                       attachment.fallback_title
      wa_id = attachment.fallback_title.to_s.gsub(/\D/, '').presence

      payload = {
        name: {
          formatted_name: formatted_name,
          first_name: meta[:first_name].presence || formatted_name,
          last_name: meta[:last_name].presence
        }.compact
      }

      if attachment.fallback_title.present?
        phone_payload = {
          phone: attachment.fallback_title,
          type: 'CELL'
        }
        phone_payload[:wa_id] = wa_id if wa_id.present?
        payload[:phones] = [phone_payload]
      end

      if meta[:email].present?
        payload[:emails] = [{
          email: meta[:email],
          type: 'WORK'
        }]
      end

      payload
    end
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{phone_id_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        recipient_type: recipient_type_for(message),
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end
end

Whatsapp::Providers::WhatsappCloudService.prepend_mod_with('Whatsapp::Providers::WhatsappCloudService')
