json.array! @conversations do |conversation|
  json.id conversation.display_id
  json.inbox_id conversation.inbox_id
  json.contact_last_seen_at conversation.contact_last_seen_at.to_i
  json.status conversation.status
  json.meta do
    if conversation.assignee
      json.assignee do
        json.partial! 'api/v1/models/agent.json.jbuilder', resource: conversation.assignee
      end
    end
  end
  if conversation.unread_incoming_messages.count.zero?
    json.messages [conversation.messages.includes([{ attachments: [{ file_attachment: [:blob] }] }]).last.try(:push_event_data)]
  else
    json.messages conversation.unread_messages.includes([:user, { attachments: [{ file_attachment: [:blob] }] }]).map(&:push_event_data)
  end
  json.muted conversation.muted?
  json.timestamp conversation.last_activity_at.to_i
end
