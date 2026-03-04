# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  include ::Whatsapp::IncomingMessageServiceHelpers

  pattr_initialize [:inbox!, :params!, :outgoing_echo]

  def perform
    processed_params

    if processed_params.try(:[], :statuses).present?
      process_statuses
    elsif messages_data.present?
      process_messages
    end
  end

  # Returns messages array for both regular messages and echo events
  def messages_data
    @processed_params&.dig(:messages) || @processed_params&.dig(:message_echoes)
  end

  private

  def process_messages
    # Handle reactions separately — they update an existing message rather than creating a new one
    return process_reaction if message_type == 'reaction'

    # We don't support ephemeral or unsupported messages, skip processing them.
    return if unprocessable_message_type?(message_type)

    # Multiple webhook events can be received for the same message due to
    # misconfigurations in the Meta business manager account.
    # We use an atomic Redis SET NX to prevent concurrent workers from both
    # processing the same message simultaneously.
    return if find_message_by_source_id(messages_data.first[:id])
    return unless lock_message_source_id!

    set_contact
    return unless @contact

    ActiveRecord::Base.transaction do
      set_conversation
      create_messages
    end
  end

  def process_statuses
    return unless find_message_by_source_id(@processed_params[:statuses].first[:id])

    update_message_with_status(@message, @processed_params[:statuses].first)
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
  end

  # Process incoming reaction webhook events.
  # WhatsApp reaction payload: { reaction: { message_id: "wamid...", emoji: "👍" } }
  # An empty emoji means the user removed the reaction.
  def process_reaction
    reaction_data = messages_data.first[:reaction]
    return if reaction_data.blank?

    reacted_message = Message.find_by(source_id: reaction_data[:message_id])
    return unless reacted_message

    update_message_reactions(reacted_message, messages_data.first[:from], reaction_data[:emoji])
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP] Error processing reaction: #{e.message}"
  end

  def update_message_reactions(message, sender_id, emoji)
    reactions = message.content_attributes&.dig('reactions') || []
    reactions.reject! { |r| r['sender'] == sender_id }
    reactions << { 'sender' => sender_id, 'emoji' => emoji, 'timestamp' => Time.current.iso8601 } if emoji.present?
    message.update!(content_attributes: message.content_attributes.merge('reactions' => reactions))
  end

  def update_message_with_status(message, status)
    message.status = status[:status]
    if status[:status] == 'failed' && status[:errors].present?
      error = status[:errors]&.first
      message.external_error = "#{error[:code]}: #{error[:title]}"
    end
    message.save!
  end

  def create_messages
    message = messages_data.first
    log_error(message) && return if error_webhook_event?(message)

    process_in_reply_to(message)

    message_type == 'contacts' ? create_contact_messages(message) : create_regular_message(message)
  end

  def create_contact_messages(message)
    message['contacts'].each do |contact|
      # Pass source_id from parent message since contact objects don't have :id
      create_message(contact, source_id: message[:id])
      attach_contact(contact)
      @message.save!
    end
  end

  def create_regular_message(message)
    create_message(message, source_id: message[:id])
    store_flow_response(message)
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  # Store WhatsApp Flow nfm_reply data in content_attributes for rich rendering
  def store_flow_response(message)
    nfm_reply = message.dig(:interactive, :nfm_reply)
    return unless nfm_reply

    response_data = parse_nfm_response_json(nfm_reply[:response_json])
    @message.content_attributes = @message.content_attributes.merge(
      'flow_response' => {
        'body' => nfm_reply[:body],
        'name' => nfm_reply[:name],
        'response_data' => response_data
      }
    )

    persist_flow_data_to_contact(response_data) if response_data.present?
  end

  def persist_flow_data_to_contact(response_data)
    return if @contact.blank? || response_data.blank?

    clean_data = response_data.except('flow_token', 'FlowToken')
    return if clean_data.blank?

    merged = (@contact.custom_attributes || {}).merge(clean_data)
    @contact.update!(custom_attributes: merged)

    note_content = clean_data.map { |k, v| "**#{k.humanize}:** #{v}" }.join("\n")
    @contact.notes.create!(content: "WhatsApp Flow Response\n\n#{note_content}", account: @inbox.account)
  rescue StandardError => e
    Rails.logger.warn "[WHATSAPP FLOW] Failed to persist flow data to contact: #{e.message}"
  end

  def set_contact
    if outgoing_echo
      set_contact_from_echo
    else
      set_contact_from_message
    end
  end

  def set_contact_from_echo
    # For echo messages, contact phone is in the 'to' field
    phone_number = messages_data.first[:to]
    waid = processed_waid(phone_number)

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: "+#{phone_number}", phone_number: "+#{phone_number}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_contact_from_message
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    waid = processed_waid(contact_params[:wa_id])

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:profile, :name), phone_number: "+#{messages_data.first[:from]}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    # Update existing contact name if ProfileName is available and current name is just phone number
    update_contact_with_profile_name(contact_params)
    fetch_whatsapp_profile_picture
  end

  def fetch_whatsapp_profile_picture
    return if @contact.blank? || @contact.avatar.attached?

    Avatar::AvatarFromWhatsappJob.perform_later(@contact)
  end

  def set_conversation
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations
                                    .where.not(status: :resolved).last
                    end
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def attach_files
    return if %w[text button interactive location contacts].include?(message_type)

    attachment_payload = messages_data.first[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

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

  def attach_location
    location = messages_data.first['location']
    location_name = location['name'] ? "#{location['name']}, #{location['address']}" : ''
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude'],
      fallback_title: location_name,
      external_url: location['url']
    )
  end

  def create_message(message, source_id: nil)
    content_attrs = outgoing_echo ? { external_echo: true } : {}
    content_attrs[:in_reply_to_external_id] = @in_reply_to_external_id if @in_reply_to_external_id.present?

    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing_echo ? :outgoing : :incoming,
      # Set status to :delivered for echo messages to prevent SendReplyJob from trying to send them
      status: outgoing_echo ? :delivered : :sent,
      sender: outgoing_echo ? nil : @contact,
      source_id: (source_id || message[:id]).to_s,
      content_attributes: content_attrs
    )
  end

  def attach_contact(contact)
    phones = contact[:phones]
    phones = [{ phone: 'Phone number is not available' }] if phones.blank?

    name_info = contact['name'] || {}
    contact_meta = {
      firstName: name_info['first_name'],
      lastName: name_info['last_name']
    }.compact

    phones.each do |phone|
      @message.attachments.new(
        account_id: @message.account_id,
        file_type: file_content_type(message_type),
        fallback_title: phone[:phone].to_s,
        meta: contact_meta
      )
    end
  end

  def update_contact_with_profile_name(contact_params)
    profile_name = contact_params.dig(:profile, :name)
    return if profile_name.blank?
    return if @contact.name == profile_name

    # Only update if current name exactly matches the phone number or formatted phone number
    return unless contact_name_matches_phone_number?

    @contact.update!(name: profile_name)
  end

  def contact_name_matches_phone_number?
    phone_number = "+#{messages_data.first[:from]}"
    formatted_phone_number = TelephoneNumber.parse(phone_number).international_number
    @contact.name == phone_number || @contact.name == formatted_phone_number
  end
end
