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

    params['messages'].select { |msg| msg['from_me'] == false }.map do |message|
      processed_message = {
        id: message['id'],
        from: message['from'],
        timestamp: message['timestamp'],
        type: message['type']
      }

      # Add context processing - use symbol keys as expected by helpers
      if message['context']&.[]('quoted_id')
        processed_message[:context] = {
          id: message['context']['quoted_id'] # Map to expected format
        }
      end

      # Handle different message types - use symbol keys (original working format) except location
      case message['type']
      when 'text'
        processed_message[:text] = message['text']
      when 'image', 'video', 'audio', 'document', 'voice'
        processed_message[message['type'].to_sym] = message[message['type']]
      when 'location'
        processed_message['location'] = message['location'] # Keep string key for location (fixed in base service)
      when 'contact'
        processed_message[:contacts] = message['contacts']
      end

      processed_message
    end
  end

  def extract_statuses_from_whapi_payload
    return [] unless params['statuses']

    params['statuses'].map do |status|
      {
        id: status['id'],
        status: map_whapi_status_code(status['code']),
        timestamp: status['timestamp']
      }
    end
  end

  def extract_contacts_from_whapi_payload
    return [] unless params['messages']

    # Extract contact info from messages
    params['messages'].map do |message|
      next if message['from_me'] == true

      {
        wa_id: message['from'],
        profile: {
          name: message['from_name'] || message['from']
        }
      }
    end.compact.uniq { |contact| contact[:wa_id] }
  end

  def process_in_reply_to(message)
    # Override to extract from WHAPI's processed structure (using symbol keys)
    @in_reply_to_external_id = message.dig(:context, :id)
  end

  def map_whapi_status_code(code)
    case code
    when 2 then 'sent'
    when 3 then 'delivered'
    when 4 then 'read'
    else 'failed'
    end
  end

  def download_attachment_file(attachment_payload)
    # Use the direct link from WHAPI webhook payload
    return nil unless attachment_payload&.[]('link')

    Down.download(attachment_payload['link'])
  rescue StandardError => e
    Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
    nil
  end
end