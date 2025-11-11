json.meta do
  json.labels @conversation.cached_label_list_array
  json.additional_attributes @conversation.additional_attributes
  json.contact @conversation.contact.push_event_data
  assignee_record = @conversation.assigned_entity
  if assignee_record.present?
    assignee_payload = if assignee_record.is_a?(AgentBot)
                         assignee_record.push_event_data(@conversation.inbox)
                       else
                         assignee_record.push_event_data
                       end
    json.assignee assignee_payload
  end
  json.assignee_type @conversation.assignee_type
  json.agent_last_seen_at @conversation.agent_last_seen_at
  json.assignee_last_seen_at @conversation.assignee_last_seen_at
end

json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
end
