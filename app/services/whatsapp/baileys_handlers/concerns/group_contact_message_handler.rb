module Whatsapp::BaileysHandlers::Concerns::GroupContactMessageHandler # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern
  include GroupConversationHandler
  include Whatsapp::BaileysHandlers::Concerns::MessageCreationHandler

  private

  def handle_group_contact_message
    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    # Lock by group jid to prevent race conditions when multiple messages
    # from the same group arrive simultaneously (e.g., Multiple contacts sending messages at the same time).
    with_contact_lock(extract_group_jid) do
      # Re-check after acquiring lock to handle race conditions where:
      # 1. An agent sends a message from Chatwoot (slow API call)
      # 2. WhatsApp sends webhook before source_id is saved
      # 3. Webhook handler times out waiting for channel lock and proceeds
      # 4. By now, source_id should be set, so we can find the message
      return if find_message_by_source_id(raw_message_id)

      process_group_message
    end
  ensure
    clear_message_source_id_from_redis if @lock_acquired
  end

  def process_group_message
    @group_contact_inbox, @group_contact = find_or_create_group_contact

    consolidate_contact(baileys_sender_phone, baileys_sender_lid, baileys_sender_identifier)
    @sender_contact = find_or_create_sender_contact
    if @sender_contact
      update_contact_whatsapp_info(@sender_contact, baileys_sender_phone, baileys_sender_identifier, name: extract_sender_name)
      try_update_contact_avatar(@sender_contact)
    end

    @conversation = find_or_create_group_conversation(@group_contact_inbox)
    add_group_member(@group_contact, @sender_contact) if @sender_contact

    build_and_save_message(
      conversation: @conversation,
      sender: @sender_contact,
      attach_media: should_attach_media?
    )
  end

  def find_or_create_participant_contact(participant)
    lid = extract_lid_from_participant(participant)
    phone = extract_phone_from_participant(participant)
    identifier = lid ? "#{lid}@lid" : nil
    source_id = lid || phone

    return nil if source_id.blank?

    consolidate_contact(phone, lid, identifier)

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: phone,
        phone_number: ("+#{phone}" if phone),
        identifier: identifier
      }
    ).perform

    update_contact_whatsapp_info(contact_inbox.contact, phone, identifier)
  end

  def consolidate_contact(phone, lid, identifier)
    return unless phone || lid

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: phone, lid: lid, identifier: identifier
    ).perform
  end

  def update_contact_whatsapp_info(contact, phone, identifier, name: nil)
    update_params = {
      phone_number: ("+#{phone}" if should_update_contact_phone?(contact, phone)),
      identifier: (identifier if should_update_contact_identifier?(contact, identifier)),
      name: (name if should_update_contact_name?(contact, name))
    }.compact

    contact.update!(update_params) if update_params.present?
    contact
  end

  def should_update_contact_phone?(contact, phone)
    phone && contact.phone_number.blank?
  end

  def should_update_contact_identifier?(contact, identifier)
    identifier && contact.identifier.blank?
  end

  def should_update_contact_name?(contact, name)
    name && (contact.name.blank? || contact.name.match?(/^\d+/))
  end

  def extract_lid_from_participant(participant)
    return nil if participant[:id].blank?

    jid_part, jid_suffix = participant[:id].split('@')
    jid_part if jid_suffix == 'lid' && jid_part.match?(/^\d+$/)
  end

  def extract_phone_from_participant(participant)
    return nil if participant[:phoneNumber].blank?

    phone = participant[:phoneNumber].split('@').first
    phone if phone.match?(/^\d+$/)
  end

  def extract_group_identifier
    extract_group_jid
  end

  def extract_group_source_id
    extract_group_jid.split('@').first
  end

  def extract_group_name
    nil
  end

  def extract_sender_identifier
    baileys_sender_identifier
  end

  def extract_sender_source_id
    baileys_sender_lid || baileys_sender_phone
  end

  def extract_sender_name
    @raw_message[:pushName] || baileys_sender_phone || baileys_sender_lid
  end

  def extract_sender_phone
    phone = baileys_sender_phone
    "+#{phone}" if phone.present?
  end

  def extract_group_jid
    @raw_message[:key][:remoteJid]
  end

  def extract_sender_jid
    return if @raw_message[:key][:participant].blank?

    @raw_message[:key][:participant]
  end

  def extract_sender_jid_alt
    @raw_message[:key][:participantAlt]
  end

  def baileys_sender_phone
    alt_jid = extract_sender_jid_alt
    if alt_jid.present?
      phone = alt_jid.split('@').first
      return phone if phone.match?(/^\d+$/)
    end

    sender_jid = extract_sender_jid
    return if sender_jid.blank?

    jid_part = sender_jid.split('@').first
    parts = jid_part.split(':')
    parts.first if parts.first.match?(/^\d+$/)
  end

  def baileys_sender_lid
    sender_jid = extract_sender_jid
    return if sender_jid.blank?

    jid_part, jid_suffix = sender_jid.split('@')
    return jid_part if jid_suffix == 'lid' && jid_part.match?(/^\d+$/)

    parts = jid_part.split(':')
    parts.last if parts.length > 1 && parts.last.match?(/^\d+$/)
  end

  def baileys_sender_identifier
    lid = baileys_sender_lid
    lid ? "#{lid}@lid" : nil
  end
end
