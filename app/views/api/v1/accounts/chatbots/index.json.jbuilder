json.payload do
  json.array! @chatbots do |chatbot|
    json.partial! 'api/v1/models/chatbot', formats: [:json], chatbot: chatbot
  end
end
