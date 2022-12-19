json.payload do
  json.conversations do
    json.array! @result[:conversations] do |conversation|
      json.partial! 'api/v1/models/conversation', formats: [:json], conversation: conversation
      json.agent do
        json.partial! 'api/v1/models/agent', formats: [:json], resource: conversation.assignee if conversation.try(:assignee).present?
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
      json.agent do
        json.partial! 'api/v1/models/agent', formats: [:json], resource: message.conversation.assignee if message.conversation.try(:assignee).present?
      end
      json.inbox do
        if message.inbox.present?
          inbox = message.inbox
          json.id inbox.id
          json.channel_id inbox.channel_id
          json.name inbox.name
          json.channel_type inbox.channel_type
        end
      end
    end
  end
end
