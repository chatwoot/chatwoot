json.id conversation.display_id
json.account_id conversation.account_id
json.created_at conversation.created_at.to_i
json.message do
  json.partial! 'message', formats: [:json], message: conversation.messages.try(:first)
end
json.contact do
  json.partial! 'contact', formats: [:json], contact: conversation.contact if conversation.try(:contact).present?
end
json.inbox do
  json.partial! 'inbox', formats: [:json], inbox: conversation.inbox if conversation.try(:inbox).present?
end
assignee_record = conversation.assigned_entity
if assignee_record.present?
  json.assignee_type conversation.assignee_type
  json.agent do
    if assignee_record.is_a?(AgentBot)
      json.partial! 'api/v1/models/agent_bot', formats: [:json], resource: assignee_record
    else
      json.partial! 'agent', formats: [:json], agent: assignee_record
    end
  end
end
