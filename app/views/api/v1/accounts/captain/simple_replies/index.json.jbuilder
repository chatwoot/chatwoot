json.payload do
  json.array! @simple_replies do |simple_reply|
    json.partial! 'api/v1/models/captain/simple_reply', simple_reply: simple_reply
  end
end

json.meta do
  json.total_count @simple_replies.count
  json.page 1
end
