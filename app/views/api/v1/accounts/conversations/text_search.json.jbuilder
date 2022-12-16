json.payload do
  json.conversations do
    json.array! @result[:conversations] do |conversation|
      json.partial! 'api/v1/models/conversation', formats: [:json], conversation: conversation
      json.agent do
        json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assignee if conversation.assignee.present?
      end
    end
  end

  json.contacts do
    json.array! @result[:contacts] do |contact|
      json.partial! 'api/v1/models/contact', formats: [:json], resource: contact
    end
  end

  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'api/v1/models/message', formats: [:json], message: message
    end
  end
end
