class Whatsapp::IncomingMessageWhapiService < Whatsapp::IncomingMessageBaseService
  # This service is a complete override of the base service to handle the specific
  # webhook structure of WHAPI. It handles incoming messages, outgoing message
  # echoes, and status updates.

  def perform
    # Handle Whapi connection status events first
    if params['events']&.any?
      correlation_id = params['correlation_id'] || SecureRandom.uuid
      Whatsapp::WhapiConnectionStatusService.new(
        channel: inbox.channel,
        params: params,
        correlation_id: correlation_id
      ).perform
      return
    end

    # The WHAPI payload can contain either 'messages' or 'statuses'
    if params['messages']&.any?
      process_messages
    elsif params['statuses']&.any?
      process_statuses
    end
  end

  private

  # Main processors

  def process_messages
    params['messages'].each do |message_params|
      # Ensure we have a consistent hash with symbols as keys
      message = message_params.with_indifferent_access

      # Ignore messages that are sent as part of a campaign
      next if message[:from_campaign] == true

      # Ignore messages from groups, WHAPI identifies them with a g.us suffix
      next if message[:chat_id]&.ends_with?('@g.us')

      if outgoing_message?(message)
        process_outgoing_message(message)
      else
        process_incoming_message(message)
      end
    end
  end

  def process_statuses
    params['statuses'].each do |status_params|
      status = status_params.with_indifferent_access
      message = find_message_by_source_id(status[:id])
      next unless message

      update_message_with_status(message, status)
    end
  end

  # Message type processors

  def process_incoming_message(message)
    # Prevent processing duplicate messages
    return if message_already_processed?(message[:id])

    with_message_processing_lock(message[:id]) do
      set_contact(message)
      return unless @contact

      set_conversation
      create_incoming_message(message)
    end
  end

  def process_outgoing_message(message)
    # This is an echo of a message sent from the business's WhatsApp account,
    # potentially from a device outside of Chatwoot. We record it in the conversation.
    return if message_already_processed?(message[:id])

    with_message_processing_lock(message[:id]) do
      contact_inbox = find_contact_inbox_for_outgoing(message)
      return unless contact_inbox

      @conversation = find_or_create_conversation(contact_inbox)
      create_outgoing_message(message)
    end
  end

  # Message creation methods

  def create_incoming_message(message)
    @message = @conversation.messages.build(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      content: extract_content(message)
    )
    process_in_reply_to(message)
    attach_files(message)
    @message.save!
  end

  def create_outgoing_message(message)
    # Outgoing messages from external sources have no agent sender
    @message = @conversation.messages.build(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :outgoing,
      sender: nil,
      source_id: message[:id].to_s,
      content: extract_content(message)
    )
    process_in_reply_to(message)
    attach_files(message)
    @message.save!
  end

  # Contact and Conversation helpers

  def set_contact(message)
    waid = processed_waid(message[:from])

    # Build basic contact attributes
    contact_attributes = {
      phone_number: "+#{message[:from]}",
      name: message[:from_name] || message[:from]
    }

    # Create or find contact first
    contact_inbox_builder = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: contact_attributes
    )
    @contact_inbox = contact_inbox_builder.perform
    @contact = @contact_inbox.contact

    # Only fetch contact info from WHAPI if we don't already have an avatar
    return if @contact.avatar.present?

    contact_info = @inbox.channel.provider_service.fetch_contact_info(message[:from])

    return unless contact_info.present?

    # Update contact with WHAPI information
    update_attributes = {}

    # Update name if WHAPI has a better name
    update_attributes[:name] = contact_info[:name] if contact_info[:name].present?

    # Add business name if available
    if contact_info[:business_name].present?
      update_attributes[:additional_attributes] = (@contact.additional_attributes || {}).merge(
        business_name: contact_info[:business_name]
      )
    end

    # Update contact if we have new information
    @contact.update!(update_attributes) if update_attributes.any?

    # Schedule avatar update if available
    return unless contact_info[:avatar_url].present?

    ::Avatar::AvatarFromUrlJob.perform_later(@contact, contact_info[:avatar_url])
  end

  def find_contact_inbox_for_outgoing(message)
    recipient_id = message[:chat_id]&.split('@')&.first || message[:to]
    return nil unless recipient_id

    waid = processed_waid(recipient_id)
    @inbox.contact_inboxes.find_by(source_id: waid)
  end

  def set_conversation
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where.not(status: :resolved).last
                    end
    @conversation ||= ::Conversation.create!(conversation_params)
  end

  def find_or_create_conversation(contact_inbox)
    conversation = if @inbox.lock_to_single_conversation
                     contact_inbox.conversations.last
                   else
                     contact_inbox.conversations.where.not(status: :resolved).last
                   end
    conversation || ::Conversation.create!(
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id
    )
  end

  # Attachment and content helpers

  def attach_files(message)
    message_type = message[:type].to_s
    return if %w[text button interactive].include?(message_type)

    attachment_payload = message[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

    case message_type
    when 'location'
      attach_location(attachment_payload)
    when 'contacts'
      attach_contacts(message[:contacts])
    else
      attach_media(attachment_payload, message_type)
    end
  end

  def attach_media(attachment_payload, message_type)
    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def attach_location(location)
    return if location.blank?

    location_name = location[:name] || location[:address] || "Location: #{location[:latitude]}, #{location[:longitude]}"
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      coordinates_lat: location[:latitude],
      coordinates_long: location[:longitude],
      fallback_title: location_name,
      external_url: location[:url]
    )
  end

  def attach_contacts(contacts)
    return if contacts.blank?

    contacts.each do |contact_payload|
      contact_name = contact_payload.is_a?(Hash) ? contact_payload.dig(:name, :formatted_name) : nil
      phones = contact_payload[:phones]
      phones = [{ phone: 'Phone number not available' }] if phones.blank?

      phones.each do |phone|
        @message.attachments.new(
          account_id: @message.account_id,
          file_type: :contact,
          fallback_title: "#{contact_name} - #{phone[:phone]}"
        )
      end
    end
  end

  def extract_content(message)
    message_type = message[:type].to_s
    return nil unless message.is_a?(Hash)

    case message_type
    when 'text'
      message.dig(:text, :body)
    when 'interactive'
      message.dig(:interactive, :button_reply, :title) || message.dig(:interactive, :list_reply, :title)
    when 'button'
      message.dig(:button, :text)
    else
      message.dig(message_type.to_sym, :caption)
    end
  end

  # Overridden helpers

  def download_attachment_file(attachment_payload)
    return nil unless attachment_payload&.[](:link)

    Down.download(attachment_payload[:link])
  rescue Down::Error => e
    Rails.logger.error "Failed to download WHAPI attachment: #{e.message}"
    nil
  end

  def process_in_reply_to(message)
    quoted_message_id = message.is_a?(Hash) ? message.dig(:context, :quoted_id) : nil
    return unless quoted_message_id

    # The base service expects `id` inside context, but WHAPI gives `quoted_id`
    # We find the message directly and assign the id to content_attributes
    in_reply_to_message = Message.find_by(source_id: quoted_message_id)
    @message.content_attributes[:in_reply_to_external_id] = in_reply_to_message&.id
  end

  def update_message_with_status(message, status)
    # WHAPI status can be a descriptive string or a code.
    status_string = status[:status] || map_whapi_status_code(status[:code])
    message.status = status_string
    message.external_error = status[:reason] if status_string == 'failed' && status[:reason].present?
    message.save!
  end

  def map_whapi_status_code(code)
    case code.to_i
    when 2 then 'sent'
    when 3 then 'delivered'
    when 4 then 'read'
    else 'failed'
    end
  end

  # Utility methods

  def outgoing_message?(message)
    message[:from_me] == true
  end

  def message_already_processed?(source_id)
    return true if find_message_by_source_id(source_id)
    # Fallback for race conditions
    return true if message_under_process?(source_id)

    false
  end

  def message_under_process?(source_id)
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: source_id)
    Redis::Alfred.get(key)
  end

  def with_message_processing_lock(source_id)
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: source_id)
    Redis::Alfred.setex(key, true, 1.minute.to_i)
    yield
  ensure
    Redis::Alfred.delete(key)
  end
end
