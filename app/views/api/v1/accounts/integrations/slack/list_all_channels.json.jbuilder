json.array! @channels do |channel|
  json.id channel['id']
  json.name channel['name']
  json.is_private channel['is_private']
end
