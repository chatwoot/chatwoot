contact = call.conversation&.contact

json.id call.id
json.call_id call.provider_call_id
json.provider call.provider
json.status call.display_status
json.direction call.direction_label
json.conversation_id call.conversation_id
json.inbox_id call.inbox_id
json.message_id call.message_id
json.accepted_by_agent_id call.accepted_by_agent_id
# Identifies the answer that was accepted without exposing it, so the device that sent it
# can tell its own answer from another device's
json.answer_digest(call.meta&.dig('sdp_answer')&.then { |answer| Digest::SHA256.hexdigest(answer) })
json.elapsed_seconds(call.started_at ? (Time.current - call.started_at).to_i : 0)
json.sdp_offer call.meta&.dig('sdp_offer')
json.ice_servers(call.meta&.dig('ice_servers') || Call.default_ice_servers)
json.recording_enabled call.recording_enabled?

if contact
  json.caller do
    json.name contact.name
    json.phone contact.phone_number
    json.avatar contact.avatar_url
  end
else
  json.caller({})
end
