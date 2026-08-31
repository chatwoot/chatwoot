class Whatsapp::CallPermissionReplyService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless inbox.channel.voice_enabled?

    reply_data = extract_reply_data
    return unless reply_data&.dig(:accepted)

    conversation = find_requesting_conversation(reply_data[:context_id])
    return unless conversation

    clear_permission_flag(conversation)
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
    { from_number: message[:from], accepted: accepted, context_id: message.dig(:context, :id) }
  end

  # Match the reply to the conversation whose request message it actually points
  # at (interactive replies carry context.id = our outbound wamid). Recency-based
  # lookup would broadcast to the wrong thread when a contact has multiple
  # parallel pending requests.
  def find_requesting_conversation(context_id)
    return if context_id.blank?

    inbox.conversations
         .where.not(status: :resolved)
         .where("additional_attributes ->> 'call_permission_request_message_id' = ?", context_id)
         .first
  end

  def clear_permission_flag(conversation)
    attrs = (conversation.additional_attributes || {}).except(
      'call_permission_requested_at', 'call_permission_request_message_id'
    )
    conversation.update!(additional_attributes: attrs)
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
