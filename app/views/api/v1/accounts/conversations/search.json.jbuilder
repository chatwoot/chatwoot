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
      json.muted conversation.muted?
      json.can_reply conversation.can_reply?
      json.timestamp conversation.messages.last.try(:created_at).try(:to_i)
      json.contact_last_seen_at conversation.contact_last_seen_at.to_i
      json.agent_last_seen_at conversation.agent_last_seen_at.to_i
      json.additional_attributes conversation.additional_attributes
      json.account_id conversation.account_id
      json.labels conversation.label_list
    end
  end
end
