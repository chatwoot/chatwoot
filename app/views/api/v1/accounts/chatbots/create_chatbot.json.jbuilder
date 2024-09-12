json.payload do
  json.partial! 'api/v1/models/chatbot', formats: [:json], chatbot: @chatbot
end
