json.id conversation.display_id
json.created_at conversation.created_at.to_i
json.contact do
  json.id conversation.contact.id
  json.name conversation.contact.name
end
json.inbox do
  json.id conversation.inbox.id
  json.name conversation.inbox.name
  json.channel_type conversation.inbox.channel_type
end
json.messages do
  json.array! conversation.messages do |message|
    json.content message.content
    json.id message.id
    json.sender_name message.sender.name if message.sender
    json.message_type message.message_type_before_type_cast
    json.created_at message.created_at.to_i
  end
end
json.account_id conversation.account_id
