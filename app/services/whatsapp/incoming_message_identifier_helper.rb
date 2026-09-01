module Whatsapp::IncomingMessageIdentifierHelper
  def process_identity_change_messages
    system_messages, @messages_data = messages_data.to_a.partition { |message| message[:type] == 'system' }
    return if system_messages.blank?

    Whatsapp::UserIdRotationService.new(inbox: inbox, messages: system_messages, job_locked_source_id: locked_sender_id).perform
  end

  def set_contact_from_echo
    message = messages_data.first
    source_ids = outgoing_message_source_ids(message)
    return if source_ids.blank?

    # The name falls back to the phone number rather than to the first source id: that one is now
    # the identifier, and a contact created by an echo alone would be displayed as `IN.2081978...`.
    contact_attributes = contact_attributes_for_identifier(message[:to].presence || source_ids.first, message[:to])
    @contact_inbox = find_or_create_contact_inbox(
      source_ids: source_ids,
      contact_attributes: contact_attributes
    )
    @contact = @contact_inbox.contact
    update_whatsapp_identifiers(source_ids: source_ids, phone_number: contact_attributes[:phone_number])
  end

  def set_contact_from_message
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    source_ids = incoming_message_source_ids(contact_params)
    return if source_ids.blank?

    attrs = contact_attributes_from_contact_params(contact_params, source_ids.first)
    @contact_inbox = find_or_create_contact_inbox(
      source_ids: source_ids,
      contact_attributes: attrs
    )
    @contact = @contact_inbox.contact
    update_whatsapp_identifiers(source_ids: source_ids, username: contact_params.dig(:profile, :username), phone_number: attrs[:phone_number])
    update_contact_with_profile_name(contact_params)
  end

  def find_or_create_contact_inbox(source_ids:, contact_attributes:)
    ContactInboxSourceIdResolver.new(
      inbox: inbox,
      source_ids: source_ids,
      contact_attributes: contact_attributes,
      prefer_first_source_id: true
    ).perform
  end

  # Preserve existing conversation history: phone history wins for mixed payloads, BSUID history
  # wins if the caller was first seen BSUID-only, and new mixed callers start on the phone.
  def incoming_message_source_ids(contact_params)
    phone_source_id = whatsapp_phone_source_id(contact_params[:wa_id].presence || messages_data.first[:from].presence)
    identifiers = [
      whatsapp_source_id(contact_params[:parent_user_id].presence || messages_data.first[:from_parent_user_id].presence),
      whatsapp_source_id(contact_params[:user_id].presence || messages_data.first[:from_user_id].presence)
    ]

    Whatsapp::IdentitySourceIdOrderer.new(inbox: inbox, phone_source_id: phone_source_id, source_ids: identifiers).perform
  end

  def addressable_identifiers?
    inbox.channel.try(:provider) == 'whatsapp_cloud'
  end

  # An echo has to land on the same alias an inbound message would, otherwise the two entry points
  # can anchor the same contact on different rows and split the thread in half.
  def outgoing_message_source_ids(message)
    phone_source_id = whatsapp_phone_source_id(message[:to].presence)
    identifiers = [
      whatsapp_source_id(message[:to_parent_user_id].presence),
      whatsapp_source_id(message[:to_user_id].presence)
    ]

    Whatsapp::IdentitySourceIdOrderer.new(inbox: inbox, phone_source_id: phone_source_id, source_ids: identifiers).perform
  end

  def whatsapp_phone_source_id(identifier)
    phone_number = whatsapp_phone_number(identifier)
    return if phone_number.blank?

    processed_waid(phone_number)
  end

  def whatsapp_source_id(identifier) = identifier.to_s.presence

  def contact_attributes_from_contact_params(contact_params, source_identifier)
    phone_identifier = contact_params[:wa_id].presence || messages_data.first[:from].presence

    contact_attributes_for_identifier(
      contact_params.dig(:profile, :name).presence || phone_identifier.presence || source_identifier,
      phone_identifier
    )
  end

  def contact_attributes_for_identifier(name, phone_identifier)
    phone_number = whatsapp_phone_number(phone_identifier)
    return { name: name } if phone_number.blank?

    formatted_phone_number = "+#{phone_number}"
    display_name = name == phone_identifier ? formatted_phone_number : name
    { name: display_name, phone_number: formatted_phone_number }
  end

  def update_whatsapp_identifiers(source_ids: [], username: nil, phone_number: nil)
    Whatsapp::IdentifierSyncService.new(contact_inbox: @contact_inbox, contact: @contact).perform(source_ids: source_ids, username: username,
                                                                                                  phone_number: phone_number)
  end

  def update_whatsapp_identifiers_from_status(status)
    contact_inbox = @message&.conversation&.contact_inbox
    return if contact_inbox.blank?

    Whatsapp::IdentifierSyncService.new(contact_inbox: contact_inbox, contact: contact_inbox.contact).perform(
      source_ids: status_source_ids(status)
    )
  end

  def status_source_ids(status)
    contact_params = @processed_params[:contacts]&.first || {}

    [
      whatsapp_source_id(status[:recipient_user_id]),
      whatsapp_source_id(status[:recipient_parent_user_id]),
      whatsapp_source_id(contact_params[:user_id]),
      whatsapp_source_id(contact_params[:parent_user_id])
    ].compact_blank.uniq
  end
end
