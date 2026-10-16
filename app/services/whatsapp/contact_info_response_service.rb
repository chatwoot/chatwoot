class Whatsapp::ContactInfoResponseService
  pattr_initialize [:contact_inbox!, :message_payload!]

  def perform
    return unless processable_response?

    request_message = pending_request_message
    return if request_message.blank? || response_predates_request?(request_message)

    phone_identity = shared_phone_identity
    return if phone_identity.blank?

    request_message.with_lock do
      return unless pending_request?(request_message)

      state = sync_contact_info_response(phone_identity)
      update_request_state(request_message, state)
      state
    end
  end

  private

  def processable_response?
    contact_payload[:origin] == 'contact_request' && matching_bsuid? && !response_already_processed?
  end

  def inbox
    contact_inbox.inbox
  end

  def contact
    contact_inbox.contact
  end

  def contact_payload
    Array(message_payload[:contacts]).first&.with_indifferent_access || {}.with_indifferent_access
  end

  def matching_bsuid?
    return false if sender_ids.blank?
    return false unless matching_contact_inboxes.exists?

    sender_ids.include?(contact_inbox.source_id)
  end

  def sender_ids
    [message_payload[:from_user_id], message_payload[:from_parent_user_id]].compact_blank.map(&:to_s).uniq
  end

  def matching_contact_inboxes
    inbox.contact_inboxes.where(contact: contact, source_id: sender_ids)
  end

  def response_already_processed?
    source_id = message_payload[:id].to_s
    return false if source_id.blank?

    contact_info_request_messages.exists?(
      ["(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'response_source_id' = ?", source_id]
    )
  end

  def pending_request_message
    contact_info_request_messages.where.not(status: :failed)
                                 .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'type' = ?", 'request')
                                 .where("(content_attributes #>> '{}')::jsonb -> 'whatsapp_contact_info' ->> 'state' = ?", 'pending')
                                 .order(created_at: :desc, id: :desc)
                                 .first
  end

  def contact_info_request_messages
    Message.outgoing.where(
      conversation_id: Conversation.where(contact_inbox: matching_contact_inboxes).select(:id)
    )
  end

  def pending_request?(message)
    message.content_attributes.dig('whatsapp_contact_info', 'type') == 'request' &&
      message.content_attributes.dig('whatsapp_contact_info', 'state') == 'pending' && !message.failed?
  end

  def response_predates_request?(request_message)
    response_timestamp = message_payload[:timestamp].to_i
    response_timestamp.positive? && response_timestamp < request_message.created_at.to_i
  end

  def shared_phone_identity
    phone = Array(contact_payload[:phones]).first&.with_indifferent_access || {}.with_indifferent_access
    wa_id = phone[:wa_id].to_s
    return { phone_number: "+#{wa_id}", source_id: wa_id } if wa_id.match?(/\A\d{1,15}\z/)

    parsed_number = TelephoneNumber.parse(phone[:phone].to_s)
    return unless parsed_number.valid?

    phone_number = parsed_number.e164_number
    { phone_number: phone_number, source_id: phone_number.delete_prefix('+') }
  end

  def identity_conflict?(phone_identity)
    phone_number = phone_identity[:phone_number]
    return true if contact.phone_number.present? && contact.phone_number != phone_number
    return true if inbox.contact_inboxes.where(source_id: phone_identity[:source_id]).where.not(contact_id: contact.id).exists?

    contact.account.contacts.where(phone_number: phone_number).where.not(id: contact.id).exists?
  end

  def sync_contact_info_response(phone_identity)
    contact.account.with_lock do
      contact.with_lock do
        contact.reload
        identity_conflict?(phone_identity) ? 'identity_conflict' : sync_phone_identity(phone_identity)
      end
    end
  end

  def sync_phone_identity(phone_identity)
    Whatsapp::IdentifierSyncService.new(contact_inbox: contact_inbox, contact: contact).perform(
      source_ids: [phone_identity[:source_id]], phone_number: phone_identity[:phone_number]
    )
    contact.reload.phone_number == phone_identity[:phone_number] ? 'shared' : 'identity_conflict'
  end

  def update_request_state(request_message, state)
    content_attributes = request_message.content_attributes.deep_dup
    content_attributes['whatsapp_contact_info']['state'] = state
    content_attributes['whatsapp_contact_info']['response_source_id'] = message_payload[:id].to_s
    request_message.update!(content_attributes: content_attributes)
  end
end
