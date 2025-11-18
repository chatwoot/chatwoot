json.meta do
  json.labels @conversation.cached_label_list_array
  json.additional_attributes @conversation.additional_attributes
  json.contact @conversation.contact.push_event_data
  json.agent_last_seen_at @conversation.agent_last_seen_at
end

json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
end
