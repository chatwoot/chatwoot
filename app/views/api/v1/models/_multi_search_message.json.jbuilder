json.id message.id
json.content message.content
json.message_type message.message_type_before_type_cast
json.content_type message.content_type
json.source_id message.source_id
json.inbox_id message.inbox_id
json.conversation_id message.conversation.try(:display_id)
json.created_at message.created_at.to_i
json.agent do
  if message.conversation.try(:assignee).present?
    json.partial! 'api/v1/models/multi_search_agent', formats: [:json], agent: message.conversation.try(:assignee)
  end
end
json.inbox do
  json.partial! 'api/v1/models/multi_search_inbox', formats: [:json], inbox: message.inbox if message.inbox.present? && message.try(:inbox).present?
end
