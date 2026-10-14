# The data sent with VoIP pushes: the ring as APNs carries it, and the ring and the
# cancel as FCM data messages
class Voice::VoipPushPayloads
  pattr_initialize [:call!]

  def ring
    contact = call.contact
    base_payload.merge(
      type: 'voice_call.incoming',
      caller: { name: contact&.name, phone: contact&.phone_number, avatar: contact&.avatar_url.presence },
      inbox_name: call.inbox.name
    )
  end

  # FCM data values must all be strings, and the caller travels as JSON
  def ring_data
    data = ring.except(:caller).transform_keys(&:to_s).transform_values(&:to_s)
    data['caller'] = ring[:caller].to_json
    data
  end

  def cancel_data
    base_payload.merge(type: 'voice_call.cancel', reason: call.status).transform_keys(&:to_s).transform_values(&:to_s)
  end

  private

  def base_payload
    {
      call_id: call.provider_call_id,
      id: call.id,
      provider: call.provider,
      direction: call.direction_label,
      # The app addresses conversations by their display id
      conversation_id: call.conversation.display_id,
      inbox_id: call.inbox_id,
      account_id: call.account_id
    }
  end
end
