json.payload do
  json.array! @internal_messages do |message|
    json.partial! 'api/v1/models/internal_message', resource: message
  end
end
