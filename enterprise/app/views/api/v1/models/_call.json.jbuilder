json.id call.id
json.call_id call.provider_call_id
json.provider call.provider
json.status call.display_status
json.direction call.direction_label
json.duration_seconds call.duration_seconds
json.end_reason call.end_reason
json.started_at call.started_at&.to_i
json.created_at call.created_at.to_i
json.message_id call.message_id
json.recording_url call.recording_url
json.transcript call.transcript

json.conversation do
  json.id call.conversation_id
  json.display_id call.conversation.display_id
end

json.inbox do
  json.id call.inbox_id
  json.name call.inbox.name
end

if call.accepted_by_agent
  json.agent do
    json.id call.accepted_by_agent.id
    json.name call.accepted_by_agent.available_name
    json.avatar call.accepted_by_agent.avatar_url
  end
else
  json.agent nil
end

contact = call.contact
json.contact do
  json.id contact.id
  json.name contact.name
  json.phone_number contact.phone_number
  json.avatar contact.avatar_url
end
