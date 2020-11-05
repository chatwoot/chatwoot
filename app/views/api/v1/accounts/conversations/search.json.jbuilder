json.data do
  json.meta do
    json.mine_count @conversations_count[:mine_count]
    json.unassigned_count @conversations_count[:unassigned_count]
    json.all_count @conversations_count[:all_count]
  end
  json.payload do
    json.array! @conversations do |conversation|
      json.inbox_id conversation.inbox_id
      json.messages conversation.messages
      json.status conversation.status
      json.account_id conversation.account_id
    end
  end
end
