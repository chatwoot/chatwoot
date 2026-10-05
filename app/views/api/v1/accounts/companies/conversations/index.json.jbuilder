json.meta do
  json.total_count @conversations.total_count
  json.all_count @all_count
  json.open_count @open_count
  json.page @conversations.current_page
end
json.payload do
  message_summaries = Conversations::MessageSummaryLoader.new(@conversations)
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation',
                  formats: [:json],
                  conversation: conversation,
                  message_summaries: message_summaries
  end
end
