json.payload do
  json.array! @copilot_messages do |message|
    json.id message.id
    json.message message.message
    json.message_type message.message_type
    json.created_at message.created_at.to_i
  end
end
