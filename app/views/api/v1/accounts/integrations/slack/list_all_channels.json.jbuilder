json.array! @channels do |channel|
  json.id channel['id']
  json.name channel['name']
end
