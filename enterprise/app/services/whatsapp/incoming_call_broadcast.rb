class Whatsapp::IncomingCallBroadcast
  pattr_initialize [:call!, :user_ids!]

  def perform
    return unless call.ringing?

    payload = { event: 'voice_call.incoming', data: data }
    User.where(id: user_ids).pluck(:pubsub_token).compact.each { |token| ActionCable.server.broadcast(token, payload) }
  end

  private

  def data
    contact = call.contact
    {
      account_id: call.account_id, id: call.id, call_id: call.provider_call_id, provider: 'whatsapp',
      conversation_id: call.conversation_id, direction: call.direction_label, inbox_id: call.inbox_id,
      sdp_offer: call.meta['sdp_offer'], ice_servers: Call.default_ice_servers,
      recording_enabled: call.recording_enabled?,
      caller: { name: contact.name, phone: contact.phone_number, avatar: contact.avatar_url }
    }
  end
end
