json.payload do
  json.conversations do
    json.array! @result[:conversations] do |conversation|
      json.partial! 'conversation_search_result', formats: [:json], conversation: conversation
    end
  end
  json.contacts do
    json.array! @result[:contacts] do |contact|
      json.partial! 'contact', formats: [:json], contact: contact
    end
  end
  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'message', formats: [:json], message: message
    end
  end
  json.articles do
    json.array! @result[:articles] do |article|
      json.partial! 'article', formats: [:json], article: article
    end
  end
end
