json.payload do
  json.array! @result[:conversations] do |conversation|
    json.partial! 'api/v1/models/conversation', formats: [:json], conversation: conversation
  end

  json.array! @result[:contacts] do |contact|
    json.partial! 'api/v1/models/contact', formats: [:json], resource: contact
  end

  json.array! @result[:messages] do |message|
    json.partial! 'api/v1/models/message', formats: [:json], message: message
  end
end
