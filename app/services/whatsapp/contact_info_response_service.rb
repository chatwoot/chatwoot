class Whatsapp::ContactInfoResponseService
  pattr_initialize [:conversation!, :inbox!, :contact!, :contact_inbox!, :message_payload!]

  def perform
    return unless contact_payload[:origin] == 'contact_request'
    return unless matching_bsuid?

    request_message = pending_request_message
    return if request_message.blank?

    phone_number = shared_phone_number
    return if phone_number.blank?

    state = identity_conflict?(phone_number) ? 'identity_conflict' : sync_phone_number(phone_number)
    update_request_state(request_message, state)
  end

  private

  def contact_payload
    message_payload[:contacts].first
  end

  def matching_bsuid?
    bsuid = message_payload[:from_user_id].to_s
    bsuid.present? && inbox.contact_inboxes.exists?(contact: contact, source_id: bsuid)
  end

  def pending_request_message
    conversation.messages.outgoing
                .where.not(status: :failed)
                .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'type' = ?", 'request')
                .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'state' = ?", 'pending')
                .order(created_at: :desc, id: :desc)
                .first
  end

  def shared_phone_number
    phone = Array(contact_payload[:phones]).first || {}
    wa_id = phone[:wa_id].to_s
    return "+#{wa_id}" if wa_id.match?(/\A\d{1,15}\z/)

    parsed_number = TelephoneNumber.parse(phone[:phone].to_s)
    parsed_number.e164_number if parsed_number.valid?
  end

  def identity_conflict?(phone_number)
    return true if contact.phone_number.present? && contact.phone_number != phone_number

    contact.account.contacts.where(phone_number: phone_number).where.not(id: contact.id).exists?
  end

  def sync_phone_number(phone_number)
    Whatsapp::IdentifierSyncService.new(contact_inbox: contact_inbox, contact: contact).perform(phone_number: phone_number)
    contact.reload.phone_number == phone_number ? 'shared' : 'identity_conflict'
  end

  def update_request_state(request_message, state)
    content_attributes = request_message.content_attributes.deep_dup
    content_attributes['whatsapp_contact_info']['state'] = state
    request_message.update!(content_attributes: content_attributes)
  end
end
