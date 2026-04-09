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
    return false unless params.dig(:entry, 0, :changes, 0, :field) == 'history'
    return false if params.dig(:entry, 0, :changes, 0, :value).blank?

    true
  end

  def sync_conversations_from_webhook
    sync_conversation_history
  end

  def sync_conversation_history
    history_data = params.dig(:entry, 0, :changes, 0, :value, :history)
    return unless history_data&.any?

    Rails.logger.info "[WHATSAPP] Processing conversation history with #{history_data.length} chunks"
    history_data.each { |chunk| process_history_chunk(chunk) }
  end

  def process_history_chunk(history_chunk)
    return unless history_chunk[:threads]&.any?

    Rails.logger.info "[WHATSAPP] Processing #{history_chunk[:threads].length} threads"
    history_chunk[:threads].each { |thread| process_history_thread(thread) }
  end

  def process_history_thread(thread)
    return unless thread[:messages]&.any?

    thread_id = thread[:id]
    Rails.logger.info "[WHATSAPP] Processing #{thread[:messages].length} messages for thread #{thread_id}"
    thread[:messages].each do |message_item|
      message_item[:wa_id] = thread_id
      process_historical_message(message_item)
    end
  end

  def process_historical_message(message_item)
    wa_id = message_item[:wa_id]
    message_id = message_item[:id]

    return Rails.logger.info("[WHATSAPP] Skipping error message #{message_id} for #{wa_id}") if message_item[:type] == 'errors'

    contact_inbox = find_contact_inbox(wa_id)
    return Rails.logger.warn("[WHATSAPP] Contact inbox not found for wa_id: #{wa_id}") unless contact_inbox

    conversation = find_or_create_conversation(contact_inbox)
    return Rails.logger.info("[WHATSAPP] Message #{message_id} already exists, skipping") if conversation.messages.exists?(source_id: message_id)

    create_historical_message(conversation, message_item)
    Rails.logger.info "[WHATSAPP] Historical message synced: #{message_id} for #{wa_id}"
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Historical message sync failed for #{message_id || 'unknown'}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def find_contact_inbox(wa_id)
    normalized_wa_id = wa_id.to_s.start_with?('+') ? wa_id.to_s : "+#{wa_id}"
    source_id = normalized_wa_id.delete('+')

    Rails.logger.info "[WHATSAPP] Finding contact inbox for #{source_id}"
    contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
    contact_inbox ||= inbox.contact_inboxes.find_by(source_id: normalized_wa_id)

    return contact_inbox if contact_inbox

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
    conversation = contact_inbox.conversations.first
    return conversation if conversation

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
    return message_item[:text][:body] if message_item[:text]

    media_type = %i[image audio video document].find { |t| message_item[t] }
    return unless media_type

    media = message_item[media_type]
    media[:caption] || (media[:filename] if media_type == :document)
  end

  def determine_message_type(message_item)
    return :outgoing if message_item.dig(:history_context, :from_me)

    :incoming
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
