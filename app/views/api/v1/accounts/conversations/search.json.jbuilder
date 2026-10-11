json.meta do
  json.mine_count @conversations_count[:mine_count]
  json.unassigned_count @conversations_count[:unassigned_count]
  json.all_count @conversations_count[:all_count]
  count_key = params[:assignee_type] == 'me' ? :mine_count : "#{params[:assignee_type]}_count".to_sym
  count_key = :all_count unless @conversations_count.key?(count_key)
  json.partial! 'api/v1/accounts/conversations/next_page', count_key: count_key
end
json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/models/conversation', formats: [:json], conversation: conversation
  end
end
