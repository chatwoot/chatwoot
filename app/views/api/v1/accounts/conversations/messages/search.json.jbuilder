json.meta do
  json.has_more @has_more
end
json.payload do
  json.array! @messages do |message|
    json.extract! message, :id, :content, :private
    json.created_at message.created_at.to_i
  end
end
