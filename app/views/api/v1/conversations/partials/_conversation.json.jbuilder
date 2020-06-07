json.meta do
  json.assignee conversation.assignee
  json.sender do
    json.channel conversation.inbox.try(:channel_type)
    json.id conversation.contact.id
    json.name conversation.contact.name
    json.thumbnail conversation.contact.avatar_url
  end
end

json.id conversation.display_id
json.account_id conversation.account_id
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.inbox_id conversation.inbox_id
json.labels conversation.label_list
json.muted conversation.muted?
json.status conversation.status
json.timestamp conversation.messages.last.try(:created_at).try(:to_i)
json.unread_count conversation.unread_incoming_messages.count
json.user_last_seen_at conversation.user_last_seen_at.to_i

if conversation.unread_incoming_messages.count.zero?
  json.messages [conversation.messages.last.try(:push_event_data)]
else
  json.messages conversation.unread_messages.map(&:push_event_data)
end
