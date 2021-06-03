json.id resource.display_id
json.inbox_id resource.inbox_id
json.contact_last_seen_at resource.contact_last_seen_at.to_i
json.status resource.status
json.messages do
  json.array! resource.messages do |message|
    json.partial! 'public/api/v1/models/message.json.jbuilder', resource: message
  end
end
json.contact resource.contact
