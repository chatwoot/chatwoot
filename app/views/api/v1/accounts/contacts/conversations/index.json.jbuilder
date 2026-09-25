if @all_count
  json.meta do
    json.total_count @conversations.total_count
    json.all_count @all_count
    json.open_count @open_count
    json.page @conversations.current_page
  end
end
json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation',
                  formats: [:json],
                  conversation: conversation
  end
end
