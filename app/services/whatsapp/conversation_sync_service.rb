class Whatsapp::ConversationSyncService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!, :params!]

  def perform
    return unless valid_sync_event?

    sync_conversations_from_webhook
  end

  private

  def valid_sync_event?
    field = params.dig(:entry, 0, :changes, 0, :field)
    return false unless %w[smb_message_echoes history].include?(field)
    return false if params.dig(:entry, 0, :changes, 0, :value).blank?

    true
  end

  def sync_conversations_from_webhook
    field = params.dig(:entry, 0, :changes, 0, :field)

    case field
    when 'smb_message_echoes'
      sync_message_echoes
    when 'history'
      sync_conversation_history
    end
  end

  def sync_message_echoes
    echoes_data = params.dig(:entry, 0, :changes, 0, :value, :message_echoes)
    return unless echoes_data

    echoes_data.each do |echo_item|
      process_message_echo(echo_item)
    end
  end

  def sync_conversation_history
    history_data = params.dig(:entry, 0, :changes, 0, :value, :messages)
    return unless history_data

    history_data.each do |message_item|
      process_historical_message(message_item)
    end
  end

  def process_message_echo(echo_item)
    wa_id = echo_item[:wa_id]
    message_id = echo_item[:message_id]
    echo_item[:timestamp]

    # Find the contact and conversation
    contact_inbox = find_contact_inbox(wa_id)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)

    # Look for existing message by WhatsApp message ID
    existing_message = conversation.messages.find_by(source_id: message_id)
    return if existing_message

    # Create echo message record
    create_echo_message(conversation, echo_item)

    Rails.logger.info "[WHATSAPP] Message echo synced: #{message_id} for #{wa_id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Message echo sync failed for #{message_id}: #{e.message}"
  end

  def process_historical_message(message_item)
    wa_id = message_item[:wa_id]
    message_id = message_item[:message_id]

    # Find the contact and conversation
    contact_inbox = find_contact_inbox(wa_id)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)

    # Look for existing message by WhatsApp message ID
    existing_message = conversation.messages.find_by(source_id: message_id)
    return if existing_message

    # Create historical message record
    create_historical_message(conversation, message_item)

    Rails.logger.info "[WHATSAPP] Historical message synced: #{message_id} for #{wa_id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Historical message sync failed for #{message_id}: #{e.message}"
  end

  def find_contact_inbox(wa_id)
    wa_id.start_with?('+') ? wa_id : "+#{wa_id}"
    source_id = wa_id # WhatsApp uses phone without + as source_id

    inbox.contact_inboxes.find_by(source_id: source_id)
  end

  def find_or_create_conversation(contact_inbox)
    # Find existing conversation or create new one
    conversation = contact_inbox.conversations.first
    return conversation if conversation

    # Create new conversation
    contact_inbox.conversations.create!(
      account: inbox.account,
      inbox: inbox,
      status: :resolved, # Historical conversations are resolved by default
      additional_attributes: {
        whatsapp_conversation_synced: true,
        whatsapp_conversation_sync_timestamp: Time.current.to_i
      }
    )
  end

  def create_echo_message(conversation, echo_item)
    message_content = echo_item[:content] || 'Message echo'

    conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      message_type: :outgoing,
      content: message_content,
      source_id: echo_item[:message_id],
      sender: nil, # Echo messages don't have a specific sender
      created_at: Time.at(echo_item[:timestamp].to_i),
      additional_attributes: {
        whatsapp_message_synced: true,
        whatsapp_message_type: 'echo',
        whatsapp_sync_timestamp: Time.current.to_i
      }
    )
  end

  def create_historical_message(conversation, message_item)
    message_content = extract_message_content(message_item)
    message_type = determine_message_type(message_item)

    conversation.messages.create!(
      account: inbox.account,
      inbox: inbox,
      message_type: message_type,
      content: message_content,
      source_id: message_item[:message_id],
      sender: message_type == :incoming ? conversation.contact : nil,
      created_at: Time.at(message_item[:timestamp].to_i),
      additional_attributes: {
        whatsapp_message_synced: true,
        whatsapp_message_type: 'historical',
        whatsapp_sync_timestamp: Time.current.to_i
      }
    )
  end

  def extract_message_content(message_item)
    # Extract content based on message type
    if message_item[:text]
      message_item[:text][:body]
    elsif message_item[:image]
      'Image message'
    elsif message_item[:document]
      'Document message'
    elsif message_item[:audio]
      'Audio message'
    elsif message_item[:video]
      'Video message'
    else
      'Message content'
    end
  end

  def determine_message_type(message_item)
    # Determine if message is incoming or outgoing based on available data
    # This is a simplified approach - in practice, you might need more sophisticated logic
    message_item[:from] ? :incoming : :outgoing
  end
end
