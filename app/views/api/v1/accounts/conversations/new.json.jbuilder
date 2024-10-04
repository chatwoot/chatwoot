json.data do
  json.payload do
    json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: @conversation
  end
end
