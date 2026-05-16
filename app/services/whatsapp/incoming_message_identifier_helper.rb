module Whatsapp::IncomingMessageIdentifierHelper
  def set_contact_from_echo
    message = messages_data.first
    source_ids = outgoing_message_source_ids(message)
    return if source_ids.blank?

    @contact_inbox = find_or_create_contact_inbox(
      source_ids: source_ids,
      contact_attributes: contact_attributes_for_identifier(source_ids.first, message[:to])
    )
    @contact = @contact_inbox.contact
    update_whatsapp_identifiers(source_ids: source_ids)
  end

  def set_contact_from_message
    contact_params = @processed_params[:contacts]&.first
    return if contact_params.blank?

    source_ids = incoming_message_source_ids(contact_params)
    return if source_ids.blank?

    @contact_inbox = find_or_create_contact_inbox(
      source_ids: source_ids,
      contact_attributes: contact_attributes_from_contact_params(contact_params, source_ids.first)
    )
    @contact = @contact_inbox.contact
    update_inbound_whatsapp_identifiers(contact_params, source_ids)
    update_contact_with_profile_name(contact_params)
  end

  def update_inbound_whatsapp_identifiers(contact_params, source_ids)
    update_whatsapp_identifiers(
      source_ids: source_ids,
      username: contact_params.dig(:profile, :username)
    )
  end

  def find_or_create_contact_inbox(source_ids:, contact_attributes:)
    existing_contact_inbox = find_contact_inbox_by_source_ids(source_ids)
    return existing_contact_inbox if existing_contact_inbox

    ::ContactInboxWithContactBuilder.new(
      source_id: source_ids.first,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform
  end

  def find_contact_inbox_by_source_ids(source_ids)
    source_ids.each do |source_id|
      contact_inbox = inbox.contact_inboxes.find_by(source_id: source_id)
      return contact_inbox if contact_inbox
    end

    nil
  end

  def incoming_message_source_ids(contact_params)
    [
      whatsapp_phone_source_id(contact_params[:wa_id].presence || messages_data.first[:from].presence),
      whatsapp_source_id(contact_params[:user_id].presence || messages_data.first[:from_user_id].presence),
      whatsapp_source_id(contact_params[:parent_user_id].presence || messages_data.first[:from_parent_user_id].presence)
    ].compact_blank.uniq
  end

  def outgoing_message_source_ids(message)
    [
      whatsapp_phone_source_id(message[:to].presence),
      whatsapp_source_id(message[:to_user_id].presence),
      whatsapp_source_id(message[:to_parent_user_id].presence)
    ].compact_blank.uniq
  end

  def whatsapp_phone_source_id(identifier)
    phone_number = whatsapp_phone_number(identifier)
    return if phone_number.blank?

    processed_waid(phone_number)
  end

  def whatsapp_source_id(identifier)
    identifier.to_s.delete_prefix('whatsapp:').presence
  end

  def contact_attributes_from_contact_params(contact_params, source_identifier)
    contact_attributes_for_identifier(
      contact_params.dig(:profile, :name).presence || source_identifier,
      contact_params[:wa_id].presence || messages_data.first[:from].presence
    )
  end

  def contact_attributes_for_identifier(name, phone_identifier)
    phone_number = whatsapp_phone_number(phone_identifier)
    return { name: name } if phone_number.blank?

    formatted_phone_number = "+#{phone_number}"
    display_name = name == phone_identifier ? formatted_phone_number : name
    { name: display_name, phone_number: formatted_phone_number }
  end

  def update_whatsapp_identifiers(source_ids: [], username: nil)
    Whatsapp::IdentifierSyncService.new(contact_inbox: @contact_inbox, contact: @contact).perform(
      source_ids: source_ids,
      username: username
    )
  end

  def update_whatsapp_identifiers_from_status(status)
    contact_inbox = @message&.conversation&.contact_inbox
    return if contact_inbox.blank?

    Whatsapp::IdentifierSyncService.new(contact_inbox: contact_inbox, contact: contact_inbox.contact).perform(
      source_ids: [
        whatsapp_source_id(status[:recipient_user_id]),
        whatsapp_source_id(status[:recipient_parent_user_id])
      ].compact_blank
    )
  end
end
