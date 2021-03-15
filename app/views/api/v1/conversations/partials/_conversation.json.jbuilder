json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact.json.jbuilder', resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assignee&.account
    json.assignee do
      json.partial! 'api/v1/models/agent.json.jbuilder', resource: conversation.assignee
    end
  end
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team.json.jbuilder', resource: conversation.team
    end
  end
end

json.id conversation.display_id
if conversation.messages.count.zero?
  json.messages []
elsif conversation.unread_incoming_messages.count.zero?
  json.messages [conversation.messages.includes([{ attachments: [{ file_attachment: [:blob] }] }]).last.try(:push_event_data)]
else
  json.messages conversation.unread_messages.includes([:user, { attachments: [{ file_attachment: [:blob] }] }]).last(10).map(&:push_event_data)
end

json.inbox_id conversation.inbox_id
json.status conversation.status
json.muted conversation.muted?
json.can_reply conversation.can_reply?
json.timestamp conversation.last_activity_at.to_i
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.unread_count conversation.unread_incoming_messages.count
json.additional_attributes conversation.additional_attributes
json.account_id conversation.account_id
json.labels conversation.label_list
