json.payload do
  message_summaries = Conversations::MessageSummaryLoader.new(@conversations)
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation',
                  formats: [:json],
                  conversation: conversation,
                  message_summaries: message_summaries
  end
end
