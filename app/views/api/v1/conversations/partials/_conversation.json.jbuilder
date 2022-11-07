json.meta do
  json.sender do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: conversation.contact
  end
  json.channel conversation.inbox.try(:channel_type)
  if conversation.assignee&.account
    json.assignee do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assignee
    end
  end
  if conversation.team.present?
    json.team do
      json.partial! 'api/v1/models/team', formats: [:json], resource: conversation.team
    end
  end
  json.hmac_verified conversation.contact_inbox&.hmac_verified
end

json.id conversation.display_id
if conversation.messages.count.zero?
  json.messages []
elsif conversation.unread_incoming_messages.count.zero?
  json.messages [conversation.messages.includes([{ attachments: [{ file_attachment: [:blob] }] }]).last.try(:push_event_data)]
else
  json.messages conversation.unread_messages.includes([:user, { attachments: [{ file_attachment: [:blob] }] }]).last(10).map(&:push_event_data)
end

json.account_id conversation.account_id
json.additional_attributes conversation.additional_attributes
json.agent_last_seen_at conversation.agent_last_seen_at.to_i
json.assignee_last_seen_at conversation.assignee_last_seen_at.to_i
json.can_reply conversation.can_reply?
json.contact_last_seen_at conversation.contact_last_seen_at.to_i
json.custom_attributes conversation.custom_attributes
json.inbox_id conversation.inbox_id
json.labels conversation.label_list
json.muted conversation.muted?
json.snoozed_until conversation.snoozed_until
json.status conversation.status
json.timestamp conversation.last_activity_at.to_i
json.unread_count conversation.unread_incoming_messages.count
