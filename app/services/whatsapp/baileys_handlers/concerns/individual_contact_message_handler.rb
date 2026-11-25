module Whatsapp::BaileysHandlers::Concerns::IndividualContactMessageHandler
  extend ActiveSupport::Concern
  include Whatsapp::BaileysHandlers::Concerns::MessageCreationHandler
  include Events::Types

  private

  def handle_individual_contact_message
    return unless extract_from_jid(type: 'lid')

    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    # Lock by contact phone to prevent race conditions when multiple messages
    # from the same contact arrive simultaneously (e.g., WhatsApp albums).
    contact_phone = extract_from_jid(type: 'pn') || extract_from_jid(type: 'lid')
    with_contact_lock(contact_phone) { process_individual_contact_message }
  ensure
    clear_message_source_id_from_redis if @lock_acquired
  end

  def process_individual_contact_message
    # Re-check after acquiring lock to handle race conditions where:
    # 1. An agent sends a message from Chatwoot (slow API call)
    # 2. WhatsApp sends webhook before source_id is saved
    # 3. Webhook handler times out waiting for channel lock and proceeds
    # 4. By now, source_id should be set, so we can find the message
    return if find_message_by_source_id(raw_message_id)

    set_contact

    unless @contact
      Rails.logger.warn "Contact not found for message: #{raw_message_id}"
      return
    end

    # The echo of a message Chatwoot sent under a reserved id is already stored; confirming it
    # before set_conversation keeps it from reopening (or opening) a thread for it.
    return if confirm_reserved_outgoing_message(@contact)

    # Reaction removals don't produce a new Message row; handle them before
    # set_conversation so a blank webhook can't open/create a stray thread.
    return mark_existing_reaction_as_removed(sender: @contact) if reaction_removal?

    return if Whatsapp::BlockedSender.silenced?(@contact, from_me: !incoming?)

    set_first_touch_attribution
    set_conversation
    handle_create_message
    dispatch_incoming_typing_off
  end

  # First-touch attribution: set before set_conversation so conversation_params
  # can persist it on the conversation created from this originating message.
  def set_first_touch_attribution
    context_info = message_context_info
    @referral = normalize_baileys_referral(context_info)
    @entry_point = normalize_baileys_entry_point(context_info)
  end

  def dispatch_incoming_typing_off
    return unless incoming?
    return unless @conversation && @contact

    Rails.configuration.dispatcher.dispatch(
      CONVERSATION_TYPING_OFF,
      Time.zone.now,
      conversation: @conversation,
      user: @contact,
      is_private: false
    )
  end

  def set_contact
    phone = extract_from_jid(type: 'pn')
    source_id = extract_from_jid(type: 'lid')
    identifier = "#{source_id}@lid"

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox,
      phone: phone,
      lid: source_id,
      identifier: identifier
    ).perform

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: { name: contact_name, phone_number: ("+#{phone}" if phone), identifier: identifier,
                            phone_number_candidates: alternate_contact_phone_numbers(phone) }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    update_contact_info(phone, identifier)
  end

  # A contact created by hand or through the API has no contact_inbox, so nothing but its
  # number finds it, and WhatsApp may report that number in another format (#776).
  def alternate_contact_phone_numbers(phone)
    Whatsapp::PhoneNumberNormalizationService.new(inbox).alternate_contact_phone_numbers(phone).presence
  end

  def update_contact_info(phone, identifier)
    update_params = {
      phone_number: ("+#{phone}" if phone),
      identifier: (identifier if @contact.identifier != identifier),
      name: (contact_name if placeholder_contact_name?(@contact.name, phone: phone, identifier: identifier))
    }.compact

    @contact.update!(update_params) if update_params.present?
    try_update_contact_avatar
  end

  def handle_create_message
    build_and_save_message(
      conversation: @conversation,
      sender: @contact,
      attach_media: should_attach_media?
    )
  end
end
