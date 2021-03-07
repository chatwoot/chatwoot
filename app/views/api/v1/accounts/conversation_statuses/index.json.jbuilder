json.payload do
  json.array! @conversation_statuses do |conversation_status|
    json.id conversation_status.id
    json.name conversation_status.name
    json.custom conversation_status.custom
  end
end
