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
    # We don't support reactions & ephemeral message now, we need to skip processing the message
    # if the webhook event is a reaction or an ephermal message or an unsupported message.
    return if unprocessable_message_type?(message_type)

    # Multiple webhook events can be received for the same message due to
    # misconfigurations in the Meta business manager account.
    # We use an atomic Redis SET NX to prevent concurrent workers from both
    # processing the same message simultaneously.
    if find_message_by_source_id(messages_data.first[:id])
      Rails.logger.info("Skipping WhatsApp webhook: message already persisted source_id=#{messages_data.first[:id]}")
      return
    end

    unless lock_message_source_id!
      Rails.logger.info("Skipping WhatsApp webhook: duplicate delivery lock active source_id=#{messages_data.first[:id]}")
      return
    end

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
    enrich_contact_from_status_webhook
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
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
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def set_contact
    if outgoing_echo
      set_contact_from_echo
    else
      set_contact_from_message
    end
  end

  def set_contact_from_echo
    # For echo messages, recipient can be either phone number ('to')
    # or business-scoped user id ('to_user_id').
    source_identifier = messages_data.first[:to] || messages_data.first[:to_user_id]
    return if source_identifier.blank?

    waid = processed_waid(source_identifier)
    phone_number = extract_phone_number(messages_data.first[:to])
    contact_name = phone_number.present? ? "+#{phone_number}" : waid

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: {
        name: contact_name,
        phone_number: phone_number.present? ? "+#{phone_number}" : nil,
        whatsapp_bsuid: messages_data.first[:to_user_id]
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
    update_contact_whatsapp_bsuid(messages_data.first[:to_user_id])
  end

  def set_contact_from_message
    contact_params = @processed_params[:contacts]&.first
    message = messages_data.first
    source_identifier = contact_params&.[](:wa_id) || contact_params&.[](:user_id) || message[:from] || message[:from_user_id]
    return if source_identifier.blank?

    waid = processed_waid(source_identifier)
    phone_number = extract_phone_number(message[:from] || contact_params&.[](:wa_id))
    profile_name = contact_params&.dig(:profile, :name)
    username = normalize_whatsapp_username(contact_params&.dig(:profile, :username))
    bsuid = contact_params&.[](:user_id) || message[:from_user_id]

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: {
        name: profile_name.presence || username.presence || waid,
        phone_number: phone_number.present? ? "+#{phone_number}" : nil,
        whatsapp_bsuid: bsuid,
        whatsapp_username: username
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    update_contact_whatsapp_bsuid(bsuid)
    update_contact_whatsapp_username(username)
    # Update existing contact name if ProfileName is available and current name is just phone number
    update_contact_with_profile_name(contact_params)
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
    extracted_phone_number = extract_phone_number(messages_data.first[:from])
    return false if extracted_phone_number.blank?

    phone_number = "+#{extracted_phone_number}"
    formatted_phone_number = TelephoneNumber.parse(phone_number).international_number
    @contact.name == phone_number || @contact.name == formatted_phone_number
  end

  def extract_phone_number(value)
    value.to_s.match?(/\A\d{1,15}\z/) ? value.to_s : nil
  end

  def update_contact_whatsapp_bsuid(bsuid)
    return if @contact.blank? || bsuid.blank?
    return if @contact.whatsapp_bsuid == bsuid

    @contact.update!(whatsapp_bsuid: bsuid)
  end

  def update_contact_whatsapp_username(username)
    return if @contact.blank? || username.blank?
    return if @contact.whatsapp_username == username

    @contact.update!(whatsapp_username: username)
  end

  def enrich_contact_from_status_webhook
    contact = @message.conversation&.contact
    return if contact.blank?

    updates = {}
    bsuid = @processed_params.dig(:statuses, 0, :recipient_user_id) || @processed_params.dig(:contacts, 0, :user_id)
    username = normalize_whatsapp_username(@processed_params.dig(:contacts, 0, :profile, :username))
    updates[:whatsapp_bsuid] = bsuid if bsuid.present? && contact.whatsapp_bsuid.blank?
    updates[:whatsapp_username] = username if username.present? && contact.whatsapp_username.blank?
    contact.update!(updates) if updates.present?
  end

  def normalize_whatsapp_username(username)
    username.to_s.sub(/\A@+/, '').presence
  end
end
