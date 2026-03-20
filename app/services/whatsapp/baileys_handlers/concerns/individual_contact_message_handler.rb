module Whatsapp::BaileysHandlers::Concerns::IndividualContactMessageHandler
  extend ActiveSupport::Concern
  include Whatsapp::BaileysHandlers::Concerns::MessageCreationHandler

  private

  def handle_individual_contact_message
    return unless extract_from_jid(type: 'lid')

    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    # Lock by contact phone to prevent race conditions when multiple messages
    # from the same contact arrive simultaneously (e.g., WhatsApp albums).
    contact_phone = extract_from_jid(type: 'pn') || extract_from_jid(type: 'lid')
    with_contact_lock(contact_phone) do
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

      set_conversation
      handle_create_message
    end
  ensure
    clear_message_source_id_from_redis if @lock_acquired
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
      contact_attributes: { name: contact_name, phone_number: ("+#{phone}" if phone), identifier: identifier }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    update_contact_info(phone, source_id, identifier)
  end

  def update_contact_info(phone, source_id, identifier)
    update_params = {
      phone_number: ("+#{phone}" if phone),
      identifier: (identifier if @contact.identifier != identifier),
      name: (contact_name if @contact.name.in?([phone, source_id, identifier]))
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
