json.payload do
  json.conversations do
    json.array! @result[:conversations] do |conversation|
      json.id conversation.display_id
      json.account_id conversation.account_id
      json.created_at conversation.created_at.to_i
      json.message do
        json.partial! 'api/v1/models/multi_search_message', formats: [:json], message: conversation.messages.try(:first)
      end
      json.contact do
        json.partial! 'api/v1/models/multi_search_contact', formats: [:json], contact: conversation.contact if conversation.try(:contact).present?
      end
      json.inbox do
        json.partial! 'api/v1/models/multi_search_inbox', formats: [:json], inbox: conversation.inbox if conversation.try(:inbox).present?
      end
      json.agent do
        json.partial! 'api/v1/models/multi_search_agent', formats: [:json], agent: conversation.assignee if conversation.try(:assignee).present?
      end
    end
  end
  json.contacts do
    json.array! @result[:contacts] do |contact|
      json.partial! 'api/v1/models/multi_search_contact', formats: [:json], contact: contact
    end
  end

  json.messages do
    json.array! @result[:messages] do |message|
      json.partial! 'api/v1/models/multi_search_message', formats: [:json], message: message
    end
  end
end
