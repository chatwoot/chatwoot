json.payload do
  json.array! @conversations_page do |conversation|
    json.partial! 'conversation', conversation: conversation, unread_count: @unread_counts[conversation.id] || 0
  end
end

json.meta do
  json.current_page @conversations_page.current_page
  json.has_next_page !@conversations_page.last_page?
end
