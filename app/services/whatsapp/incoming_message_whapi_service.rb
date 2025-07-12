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
    return [] unless params['messages']

    params['messages']
      .reject { |message| outgoing_message?(message) }
      .map { |message| transform_whapi_contact(message) }
      .compact
      .uniq { |contact| contact[:wa_id] }
  end

  def process_in_reply_to(message)
    @in_reply_to_external_id = message.dig(:context, :id)
  end

  def download_attachment_file(attachment_payload)
    return nil unless attachment_payload&.[]('link')

    Down.download(attachment_payload['link'])
  rescue StandardError => e
    Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
    nil
  end

  def create_message(message)
    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type_for(message),
      sender: sender_for(message),
      source_id: message[:id].to_s,
      in_reply_to_external_id: @in_reply_to_external_id
    )
  end

  def set_contact
    message = @processed_params[:messages].first

    if outgoing_message?(message)
      set_contact_for_outgoing_message(message)
    else
      set_contact_for_incoming_message
    end
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
      from_me: message['from_me']
    }.tap do |processed_message|
      processed_message[:to] = message['to'] if message['to'].present?
    end
  end

  def add_context_to_message(processed_message, original_message)
    return unless original_message['context']&.[]('quoted_id')

    processed_message[:context] = {
      id: original_message['context']['quoted_id']
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
      status: map_whapi_status_code(status['code']),
      timestamp: status['timestamp']
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

  # Message direction and type methods

  def outgoing_message?(message)
    message['from_me'] == true || message[:from_me] == true
  end

  def message_type_for(message)
    outgoing_message?(message) ? :outgoing : :incoming
  end

  def sender_for(message)
    outgoing_message?(message) ? nil : @contact
  end

  # Contact handling methods

  def set_contact_for_outgoing_message(message)
    recipient_phone = message[:to] || message[:from]

    @contact_inbox = find_or_create_contact_inbox_for_outgoing(recipient_phone)
    @contact = @contact_inbox.contact
  end

  def set_contact_for_incoming_message
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    waid = processed_waid(contact_params[:wa_id])
    @contact_inbox = build_contact_inbox_for_incoming(waid, contact_params)
    @contact = @contact_inbox.contact
  end

  def find_or_create_contact_inbox_for_outgoing(recipient_phone)
    @inbox.contact_inboxes.find_by(source_id: recipient_phone) ||
      create_contact_inbox_for_outgoing(recipient_phone)
  end

  def create_contact_inbox_for_outgoing(recipient_phone)
    ::ContactInboxWithContactBuilder.new(
      source_id: recipient_phone,
      inbox: inbox,
      contact_attributes: {
        name: recipient_phone,
        phone_number: "+#{recipient_phone}"
      }
    ).perform
  end

  def build_contact_inbox_for_incoming(waid, contact_params)
    ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: {
        name: contact_params.dig(:profile, :name),
        phone_number: "+#{@processed_params[:messages].first[:from]}"
      }
    ).perform
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