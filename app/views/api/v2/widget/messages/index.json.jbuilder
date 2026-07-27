json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/widget_message', resource: message
  end
end

json.meta do
  json.contact_last_seen_at @conversation.contact_last_seen_at.to_i
end
