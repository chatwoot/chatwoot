json.user do
  json.id @user.id
  json.name @user.name
end

json.conversations @conversations do |conversation|
  last_message = @last_messages_by_conversation[conversation.id]

  json.id conversation.display_id
  json.status conversation.status
  json.last_activity_at conversation.last_activity_at
  json.inbox_id conversation.inbox_id

  json.contact do
    if conversation.contact
      json.id conversation.contact.id
      json.name conversation.contact.name
      json.thumbnail conversation.contact.avatar_url
    end
  end

  json.last_message do
    if last_message
      json.content last_message.content.to_s.truncate(140)
      json.created_at last_message.created_at
      json.message_type last_message.message_type
      json.private last_message.private
    end
  end
end
