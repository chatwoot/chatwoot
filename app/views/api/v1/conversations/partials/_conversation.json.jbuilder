json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact.json.jbuilder', resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assignee
    json.assignee do
      json.partial! 'api/v1/models/user.json.jbuilder', resource: conversation.assignee
    end
  end
end

json.id conversation.display_id
if conversation.unread_incoming_messages.count.zero?
  json.messages [conversation.messages.last.try(:push_event_data)]
else
  json.messages conversation.unread_messages.includes([:user, :attachments]).map(&:push_event_data)
end

json.inbox_id conversation.inbox_id
json.status conversation.status
json.muted conversation.muted?
json.can_reply conversation.can_reply?
json.timestamp conversation.messages.last.try(:created_at).try(:to_i)
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.unread_count conversation.unread_incoming_messages.count
json.additional_attributes conversation.additional_attributes
json.account_id conversation.account_id
json.labels conversation.label_list
