json.id resource.display_id
json.uuid resource.uuid
json.inbox_id resource.inbox_id
json.contact_last_seen_at resource.contact_last_seen_at.to_i
json.status resource.status
json.agent_last_seen_at resource.agent_last_seen_at.to_i
json.messages do
  json.array! resource.messages.chat do |message|
    json.partial! 'public/api/v1/models/message', formats: [:json], resource: message
  end
end
json.contact resource.contact
