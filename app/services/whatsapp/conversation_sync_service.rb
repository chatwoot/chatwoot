class Whatsapp::ConversationSyncService
  include Rails.application.routes.url_helpers
  include ::Whatsapp::IncomingMessageServiceHelpers

  pattr_initialize [:inbox!, :params!]

  def perform
    return unless valid_sync_event?

    if history_sync_event?
      process_history_sync
    elsif message_echo_event?
      process_message_echo
    end
  end

  private

  def valid_sync_event?
    # Check for history sync or message echo events
    history_sync_event? || message_echo_event?
  end

  def history_sync_event?
    params.dig(:entry, 0, :changes, 0, :field) == 'history'
  end

  def message_echo_event?
    params.dig(:entry, 0, :changes, 0, :field) == 'smb_message_echoes'
  end

  def process_history_sync
    history_data = params.dig(:entry, 0, :changes, 0, :value, :history)

    return handle_history_sync_error if history_data&.dig(0, :errors).present?

    history_data.each do |history_item|
      next if history_item[:data].blank?

      sync_historical_data(history_item[:data])
    end
  end

  def handle_history_sync_error
    error_info = params.dig(:entry, 0, :changes, 0, :value, :history, 0, :errors, 0)
    Rails.logger.warn "[WHATSAPP] History sync declined or failed: #{error_info[:message]}"
  end

  def sync_historical_data(data)
    contacts = data[:contacts] || []
    messages = data[:messages] || []

    # First, ensure contacts exist
    contacts.each { |contact_data| create_contact_from_history(contact_data) }

    # Then, sync historical messages
    messages.each { |message_data| create_message_from_history(message_data) }
  end

  def create_contact_from_history(contact_data)
    phone_number = contact_data[:wa_id]
    contact_name = contact_data.dig(:profile, :name) || phone_number

    ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: contact_name,
        phone_number: format_phone_number(phone_number),
        additional_attributes: {
          whatsapp_contact_synced: true,
          whatsapp_history_synced: true,
          whatsapp_history_sync_timestamp: Time.current.to_i
        }
      }
    ).perform
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Failed to create contact from history: #{e.message}"
  end

  def create_message_from_history(message_data)
    return unless valid_message_data?(message_data)

    phone_number = message_data[:from]
    contact_inbox = find_or_create_contact_inbox(phone_number)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)
    return unless conversation

    create_historical_message(message_data, conversation, contact_inbox.contact)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Failed to create historical message: #{e.message}"
  end

  def process_message_echo
    message_echoes = params.dig(:entry, 0, :changes, 0, :value, :message_echoes) || []

    message_echoes.each do |echo_data|
      create_echo_message(echo_data)
    end
  end

  def create_echo_message(echo_data)
    return unless valid_echo_data?(echo_data)

    to_phone_number = echo_data[:to]
    echo_data[:from]

    # Find the contact this message was sent to
    contact_inbox = find_contact_inbox_by_phone(to_phone_number)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)
    return unless conversation

    # Create outgoing message (sent from business via WhatsApp Business App)
    create_echo_message_record(echo_data, conversation, contact_inbox.contact)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Failed to create echo message: #{e.message}"
  end

  def valid_message_data?(message_data)
    message_data[:id].present? &&
      message_data[:from].present? &&
      message_data[:timestamp].present? &&
      message_data[:type].present?
  end

  def valid_echo_data?(echo_data)
    echo_data[:id].present? &&
      echo_data[:to].present? &&
      echo_data[:from].present? &&
      echo_data[:timestamp].present? &&
      echo_data[:type].present?
  end

  def find_or_create_contact_inbox(phone_number)
    contact_inbox = inbox.contact_inboxes.find_by(source_id: phone_number)
    return contact_inbox if contact_inbox

    # Create contact if not exists
    ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: format_phone_number(phone_number),
        phone_number: format_phone_number(phone_number),
        additional_attributes: {
          whatsapp_history_synced: true
        }
      }
    ).perform
  end

  def find_contact_inbox_by_phone(phone_number)
    # For echo messages, we need to find contact by their WhatsApp ID (without +)
    inbox.contact_inboxes.find_by(source_id: phone_number)
  end

  def find_or_create_conversation(contact_inbox)
    # Look for existing conversation or create new one
    conversation = if inbox.lock_to_single_conversation
                     contact_inbox.conversations.last
                   else
                     contact_inbox.conversations.where.not(status: :resolved).last
                   end

    return conversation if conversation

    ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      additional_attributes: {
        whatsapp_history_synced: true
      }
    )
  end

  def create_historical_message(message_data, conversation, contact)
    # Skip if message already exists
    return if conversation.messages.find_by(source_id: message_data[:id])

    message_content = extract_message_content(message_data)
    external_timestamp = Time.zone.at(message_data[:timestamp].to_i)

    message = conversation.messages.build(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: contact,
      source_id: message_data[:id],
      created_at: external_timestamp,
      content_attributes: {
        external_created_at: external_timestamp.iso8601,
        whatsapp_history_synced: true
      }
    )

    # Handle different message types
    case message_data[:type]
    when 'image', 'audio', 'video', 'document'
      attach_media_from_history(message, message_data)
    when 'location'
      attach_location_from_history(message, message_data)
    end

    message.save!
    Rails.logger.info "[WHATSAPP] Historical message synced: #{message_data[:id]}"
  end

  def create_echo_message_record(echo_data, conversation, _contact)
    # Skip if message already exists
    return if conversation.messages.find_by(source_id: echo_data[:id])

    message_content = extract_message_content(echo_data)
    external_timestamp = Time.zone.at(echo_data[:timestamp].to_i)

    message = conversation.messages.build(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: :outgoing, # This is a message sent by the business
      sender: nil, # Business messages don't have a sender contact
      source_id: echo_data[:id],
      created_at: external_timestamp,
      content_attributes: {
        external_created_at: external_timestamp.iso8601,
        whatsapp_echo_message: true
      }
    )

    message.save!
    Rails.logger.info "[WHATSAPP] Echo message synced: #{echo_data[:id]}"
  end

  def extract_message_content(message_data)
    case message_data[:type]
    when 'text'
      message_data.dig(:text, :body)
    when 'image', 'audio', 'video', 'document'
      message_data.dig(message_data[:type].to_sym, :caption) || message_data[:type].humanize
    when 'location'
      location = message_data[:location]
      "Location: #{location[:name] || 'Shared location'}"
    else
      message_data[:type].humanize
    end
  end

  def attach_media_from_history(message, message_data)
    # NOTE: Historical media might not be available for download
    # We'll just record the media info in content_attributes
    media_data = message_data[message_data[:type].to_sym] || {}

    message.content_attributes[:media_info] = {
      type: message_data[:type],
      caption: media_data[:caption],
      filename: media_data[:filename],
      mime_type: media_data[:mime_type],
      sha256: media_data[:sha256],
      id: media_data[:id]
    }
  end

  def attach_location_from_history(message, message_data)
    location = message_data[:location] || {}

    message.content_attributes[:location_info] = {
      latitude: location[:latitude],
      longitude: location[:longitude],
      name: location[:name],
      address: location[:address],
      url: location[:url]
    }
  end

  def format_phone_number(phone_number)
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def account
    @account ||= inbox.account
  end
end