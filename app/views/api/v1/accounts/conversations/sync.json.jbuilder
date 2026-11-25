json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: conversation
  end
end
