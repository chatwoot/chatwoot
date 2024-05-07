json.payload do
  json.array! @smart_actions do |smart_action|
    json.partial! 'api/v1/models/smart_action', smart_action: smart_action
  end
end
