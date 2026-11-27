class Whatsapp::CallPermissionReplyService
  REQUESTS_KEY = 'call_permission_requests'.freeze
  REQUESTED_AT_KEY = 'call_permission_requested_at'.freeze
  MESSAGE_ID_KEY = 'call_permission_request_message_id'.freeze
  # On the contact, per inbox: whether the customer lets that number call them, and until when
  CONTACT_PERMISSIONS_KEY = 'whatsapp_call_permissions'.freeze

  pattr_initialize [:inbox!, :params!]

  def perform
    return unless inbox.channel.voice_enabled?

    reply_data = extract_reply_data
    return unless reply_data

    record_contact_permission(reply_data)
    return unless reply_data[:accepted]

    conversation = find_requesting_conversation(reply_data[:context_id])
    return unless conversation

    clear_permission_flag(conversation, reply_data[:context_id])
    emit_permission_granted_activity(conversation)
    broadcast_permission_granted(conversation.contact, conversation)
  end

  private

  def emit_permission_granted_activity(conversation)
    content = I18n.t(
      'conversations.activity.whatsapp_call.permission_granted',
      contact_name: conversation.contact.name
    )
    ::Conversations::ActivityMessageJob.perform_later(
      conversation,
      { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
    )
  end

  def extract_reply_data
    message = params.dig(:entry, 0, :changes, 0, :value, :messages, 0)
    reply = message&.dig(:interactive, :call_permission_reply)
    return unless reply

    accepted = reply[:response] == 'accept'
    Rails.logger.info "[WHATSAPP CALL] call_permission_reply from=#{message[:from]} accepted=#{accepted} permanent=#{reply[:is_permanent]}"
    { sources: [message[:from], message[:from_user_id]].compact, accepted: accepted, context_id: message.dig(:context, :id),
      permission: { 'permanent' => reply[:is_permanent] == true, 'expires_at' => expiry_time(reply[:expiration_timestamp]) } }
  end

  def expiry_time(timestamp)
    Time.zone.at(timestamp.to_i).iso8601 if timestamp.present?
  end

  # Covers replies to our requests, WhatsApp's post-call prompt and its revocation after unanswered calls
  def record_contact_permission(reply_data)
    contact = inbox.contact_inboxes.find_by(source_id: reply_data[:sources])&.contact
    return unless contact

    contact.with_lock do
      attributes = contact.additional_attributes || {}
      permissions = attributes.fetch(CONTACT_PERMISSIONS_KEY, {}).except(inbox.id.to_s)
      permissions[inbox.id.to_s] = reply_data[:permission] if reply_data[:accepted]
      contact.update!(additional_attributes: attributes.merge(CONTACT_PERMISSIONS_KEY => permissions))
    end
  end

  # Match the reply to the conversation whose request message it actually points
  # at (interactive replies carry context.id = our outbound wamid). Recency-based
  # lookup would broadcast to the wrong thread when a contact has multiple
  # parallel pending requests.
  def find_requesting_conversation(context_id)
    return if context_id.blank?

    inbox.conversations
         .where.not(status: :resolved)
         .where(
           <<~SQL.squish, context_id, context_id
             additional_attributes ->> '#{MESSAGE_ID_KEY}' = ?
             OR EXISTS (
               SELECT 1 FROM jsonb_each(additional_attributes -> '#{REQUESTS_KEY}') AS request(recipient, data)
               WHERE data ->> '#{MESSAGE_ID_KEY}' = ?
             )
           SQL
         )
         .first
  end

  def clear_permission_flag(conversation, context_id)
    conversation.with_lock do
      attrs = conversation.additional_attributes || {}
      permission_requests = attrs.fetch(REQUESTS_KEY, {}).reject { |_recipient, request| request[MESSAGE_ID_KEY] == context_id }

      attrs = attrs.except(REQUESTED_AT_KEY, MESSAGE_ID_KEY) if attrs[MESSAGE_ID_KEY] == context_id
      attrs = attrs.merge(REQUESTS_KEY => permission_requests)
      attrs = attrs.except(REQUESTS_KEY) if permission_requests.blank?
      conversation.update!(additional_attributes: attrs)
    end
  end

  def broadcast_permission_granted(contact, conversation)
    ActionCable.server.broadcast(
      "account_#{inbox.account_id}",
      {
        event: 'voice_call.permission_granted',
        data: {
          account_id: inbox.account_id, conversation_id: conversation.id,
          contact_name: contact.name, contact_phone: contact.phone_number
        }
      }
    )
  end
end
