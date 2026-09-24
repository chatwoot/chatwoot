json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/models/widget_conversation',
                  resource: conversation,
                  unread_count: @unread_counts.fetch(conversation.id, 0),
                  last_message: @last_messages[conversation.id]
  end
end

json.meta do
  json.has_next_page !@conversations.last_page?
  json.unread_count @unread_conversation_count
end
