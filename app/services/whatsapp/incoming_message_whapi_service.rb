class Whatsapp::IncomingMessageWhapiService < Whatsapp::IncomingMessageBaseService
  private

  def processed_params
    @processed_params ||= {
      messages: extract_messages_from_whapi_payload,
      statuses: extract_statuses_from_whapi_payload,
      contacts: extract_contacts_from_whapi_payload
    }
  end

  def extract_messages_from_whapi_payload
    return [] unless params['messages']

    params['messages'].map { |message| transform_whapi_message(message) }
  end

  def extract_statuses_from_whapi_payload
    return [] unless params['statuses']

    params['statuses'].map { |status| transform_whapi_status(status) }
  end

  def extract_contacts_from_whapi_payload
    # First check if contacts are provided directly in the payload
    return params['contacts'].map { |contact| transform_direct_contact(contact) } if params['contacts'].present?

    # Fallback to extracting from messages if no direct contacts
    return [] unless params['messages']

    params['messages']
      .reject { |message| outgoing_message?(message) }
      .filter_map { |message| transform_whapi_contact(message) }
      .uniq { |contact| contact[:wa_id] }
  end

  def download_attachment_file(attachment_payload)
    return nil unless attachment_payload&.[]('link')

    Down.download(attachment_payload['link'])
  rescue StandardError => e
    Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
    nil
  end

  def outgoing_message?(message)
    message['from_me'] == true || message[:from_me] == true
  end

  def create_message(message)
    content_attrs = {}
    content_attrs[:in_reply_to_external_id] = @in_reply_to_external_id if @in_reply_to_external_id.present?

    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      content_attributes: content_attrs
    )
  end

  # Message transformation methods

  def transform_whapi_message(message)
    base_message = build_base_message_structure(message)
    add_context_to_message(base_message, message)
    add_content_to_message(base_message, message)
    base_message
  end

  def build_base_message_structure(message)
    {
      id: message['id'],
      from: message['from'],
      timestamp: message['timestamp'],
      type: message['type'],
      from_me: message['from_me'],
      chat_id: message['chat_id']
    }.tap do |processed_message|
      processed_message[:to] = message['to'] if message['to'].present?
    end
  end

  def add_context_to_message(processed_message, original_message)
    return unless original_message['context']&.[]('quoted_id')

    # Transform the context so the base service can find it as 'id'
    processed_message['context'] = {
      'id' => original_message['context']['quoted_id']
    }
  end

  def add_content_to_message(processed_message, original_message)
    case original_message['type']
    when 'text'
      processed_message[:text] = original_message['text']
    when 'image', 'video', 'audio', 'document', 'voice'
      processed_message[original_message['type'].to_sym] = original_message[original_message['type']]
    when 'location'
      processed_message['location'] = original_message['location']
    when 'contact'
      processed_message[:contacts] = original_message['contacts']
    end
  end

  def transform_whapi_status(status)
    {
      id: status['id'],
      status: status['status'] || map_whapi_status_code(status['code']),
      timestamp: status['timestamp']
    }
  end

  def transform_direct_contact(contact)
    {
      wa_id: contact['wa_id'],
      profile: {
        name: contact.dig('profile', 'name') || contact['wa_id']
      }
    }
  end

  def transform_whapi_contact(message)
    {
      wa_id: message['from'],
      profile: {
        name: message['from_name'] || message['from']
      }
    }
  end

  # Status mapping

  def map_whapi_status_code(code)
    case code
    when 2 then 'sent'
    when 3 then 'delivered'
    when 4 then 'read'
    else 'failed'
    end
  end
end