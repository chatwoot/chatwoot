json.payload do
  json.array! @chat_status_items do |chat_status_item|
    json.id chat_status_item.id
    json.name chat_status_item.name
    json.custom chat_status_item.custom
  end
end
