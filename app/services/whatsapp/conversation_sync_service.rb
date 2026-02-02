class Whatsapp::ConversationSyncService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!, :params!]

  MEDIA_TYPES = %w[image audio video document sticker voice].freeze

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
      create_echo_message(echo_item)
    end
  end

  def sync_conversation_history
    history_data = params.dig(:entry, 0, :changes, 0, :value, :history)
    return unless history_data&.any?

    Rails.logger.info "[WHATSAPP] Processing conversation history with #{history_data.length} chunks"

    history_data.each do |history_chunk|
      next unless history_chunk[:threads]&.any?

      Rails.logger.info "[WHATSAPP] Processing #{history_chunk[:threads].length} threads"

      history_chunk[:threads].each do |thread|
        next unless thread[:messages]&.any?

        thread_id = thread[:id]
        Rails.logger.info "[WHATSAPP] Processing #{thread[:messages].length} messages for thread #{thread_id}"

        thread[:messages].each do |message_item|
          # Set wa_id from thread id for contact lookup
          message_item[:wa_id] = thread_id
          process_historical_message(message_item)
        end
      end
    end
  end

  def process_historical_message(message_item)
    wa_id = message_item[:wa_id]
    message_id = message_item[:id] # Use :id instead of :message_id for history messages

    # Skip error messages that don't contain actual content
    if message_item[:type] == 'errors'
      Rails.logger.info "[WHATSAPP] Skipping error message #{message_id} for #{wa_id}"
      return
    end

    # Find the contact and conversation
    contact_inbox = find_contact_inbox(wa_id)
    unless contact_inbox
      Rails.logger.warn "[WHATSAPP] Contact inbox not found for wa_id: #{wa_id}"
      return
    end

    conversation = find_or_create_conversation(contact_inbox)

    # Look for existing message by WhatsApp message ID
    existing_message = conversation.messages.find_by(source_id: message_id)
    if existing_message
      Rails.logger.info "[WHATSAPP] Message #{message_id} already exists, skipping"
      return
    end

    # Create historical message record
    create_historical_message(conversation, message_item)

    Rails.logger.info "[WHATSAPP] Historical message synced: #{message_id} for #{wa_id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Historical message sync failed for #{message_id || 'unknown'}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def find_contact_inbox(wa_id)
    # Ensure wa_id has + prefix for consistent lookup
    normalized_wa_id = wa_id.to_s.start_with?('+') ? wa_id.to_s : "+#{wa_id}"

    # WhatsApp contact inboxes use the phone number without + as source_id
    source_id = normalized_wa_id.delete('+')

    Rails.logger.info "[WHATSAPP] Finding contact inbox for #{source_id}"
    contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
    contact_inbox ||= inbox.contact_inboxes.find_by(source_id: normalized_wa_id)

    return contact_inbox if contact_inbox

    # Create a contact and contact inbox if not found to avoid dropping history/echoes
    Rails.logger.info "[WHATSAPP] Contact inbox not found for wa_id: #{wa_id}, creating one"
    ::ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: source_id,
      contact_attributes: {
        name: normalized_wa_id,
        phone_number: normalized_wa_id
      }
    ).perform
  end

  def find_or_create_conversation(contact_inbox)
    # Find existing conversation or create new one
    conversation = contact_inbox.conversations.first
    return conversation if conversation

    # Create new conversation
    # Note: Status defaults to 'open' based on Conversation model's determine_conversation_status callback
    contact_inbox.conversations.create!(
      account: inbox.account,
      inbox: inbox,
      contact: contact_inbox.contact,
      additional_attributes: {
        whatsapp_conversation_synced: true,
        whatsapp_conversation_sync_timestamp: Time.current.to_i
      }
    )
  end

  def create_echo_message(echo_item)
    Rails.logger.debug { "[WHATSAPP] Creating echo message: #{echo_item}" }
    wa_id = echo_item[:to]
    message_id = echo_item[:id]
    message_type = echo_item[:type]
    message_content = extract_message_content(echo_item)

    contact_inbox = find_contact_inbox(wa_id)
    return unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)

    return if conversation.messages.find_by(source_id: message_id)

    message = conversation.messages.build(
      account: inbox.account,
      inbox: inbox,
      message_type: :outgoing,
      content: message_content,
      source_id: message_id,
      sender: nil,
      created_at: Time.zone.at(echo_item[:timestamp].to_i),
      additional_attributes: {
        whatsapp_message_synced: true,
        whatsapp_message_type: 'echo',
        whatsapp_sync_timestamp: Time.current.to_i
      }
    )

    attach_media(message, echo_item, message_type) if MEDIA_TYPES.include?(message_type)
    message.save!
  end

  def create_historical_message(conversation, message_item)
    message_content = extract_message_content(message_item)
    msg_direction = determine_message_type(message_item)
    media_type = message_item[:type]

    message = conversation.messages.build(
      account: inbox.account,
      inbox: inbox,
      message_type: msg_direction,
      content: message_content,
      source_id: message_item[:id],
      sender: msg_direction == :incoming ? conversation.contact : nil,
      created_at: Time.zone.at(message_item[:timestamp].to_i),
      additional_attributes: {
        whatsapp_message_synced: true,
        whatsapp_message_type: 'historical',
        whatsapp_sync_timestamp: Time.current.to_i
      }
    )

    attach_media(message, message_item, media_type) if MEDIA_TYPES.include?(media_type)
    message.save!
  end

  def extract_message_content(message_item)
    # Extract content based on message type, including captions for media
    if message_item[:text]
      message_item[:text][:body]
    elsif message_item[:image]
      message_item[:image][:caption]
    elsif message_item[:document]
      message_item[:document][:caption] || message_item[:document][:filename]
    elsif message_item[:audio]
      message_item[:audio][:caption]
    elsif message_item[:video]
      message_item[:video][:caption]
    elsif message_item[:sticker]
      nil
    elsif message_item[:voice]
      nil
    end
  end

  def determine_message_type(message_item)
    if message_item.dig(:history_context, :from_me)
      :outgoing
    elsif message_item[:from]
      :incoming
    else
      :incoming
    end
  end

  def attach_media(message, message_item, message_type)
    attachment_payload = message_item[message_type.to_sym]
    return unless attachment_payload&.dig(:id)

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    message.attachments.new(
      account_id: message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_payload[:filename] || attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  rescue Down::Error => e
    Rails.logger.error "[WHATSAPP] Failed to download media attachment: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Error attaching media: #{e.message}"
  end

  def download_attachment_file(attachment_payload)
    media_id = attachment_payload[:id]
    return unless media_id

    url_response = HTTParty.get(
      inbox.channel.media_url(media_id),
      headers: inbox.channel.api_headers
    )

    if url_response.unauthorized?
      inbox.channel.authorization_error!
      return
    end

    return unless url_response.success?

    Down.download(url_response.parsed_response['url'], headers: inbox.channel.api_headers)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if file_type == 'video'

    :file
  end
end
