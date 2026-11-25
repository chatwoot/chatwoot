module Whatsapp::BaileysHandlers::PresenceUpdate
  include Events::Types

  private

  def process_presence_update
    return unless presence_subscribe_enabled?

    data = processed_params[:data]
    return if data[:id].blank? || data[:id].include?('@g.us')

    dispatch_presence_events(data)
  end

  def presence_subscribe_enabled?
    inbox.channel.provider_config&.dig('presence_subscribe')
  end

  def dispatch_presence_events(data)
    lid, phone = extract_presence_identifiers(data)
    consolidate_presence_contact(lid, phone) if lid && phone

    data[:presences]&.each_value do |presence_data|
      handle_presence(lid, phone, presence_data)
    end
  end

  def extract_presence_identifiers(data)
    jid = data[:id]
    lid = extract_jid_user(jid) if jid&.include?('@lid')
    # Whichever of the two addresses is a phone one, asked the same way everywhere else:
    # a phone number is what a phone jid carries, never what a digit string looks like.
    phone = phone_from_jid(jid) || phone_from_jid(data[:jidAlt])
    [lid, phone]
  end

  def handle_presence(lid, phone, presence_data)
    event = presence_event(presence_data[:lastKnownPresence])
    return unless event

    contact_inbox = find_presence_contact_inbox(lid, phone)
    return unless contact_inbox

    conversation = inbox.conversations.where(contact_id: contact_inbox.contact_id).where.not(status: :resolved).last
    return unless conversation

    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: contact_inbox.contact, is_private: false)
  end

  def find_presence_contact_inbox(lid, phone)
    contact_inbox = inbox.contact_inboxes.find_by(source_id: lid) if lid
    contact_inbox ||= inbox.contact_inboxes.find_by(source_id: phone) if phone
    contact_inbox ||= find_contact_inbox_by_phone(phone) if phone
    contact_inbox
  end

  def find_contact_inbox_by_phone(phone)
    contact = inbox.contacts.find_by(phone_number: "+#{phone}")
    return unless contact

    inbox.contact_inboxes.find_by(contact_id: contact.id)
  end

  def consolidate_presence_contact(lid, phone)
    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: phone, lid: lid, identifier: "#{lid}@lid"
    ).perform
  end

  def extract_jid_user(jid)
    return unless jid

    jid.split('@').first.split(':').first
  end

  def presence_event(status)
    case status
    when 'composing' then CONVERSATION_TYPING_ON
    when 'recording' then CONVERSATION_RECORDING
    when 'paused', 'unavailable', 'available' then CONVERSATION_TYPING_OFF
    end
  end
end
