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
json.agent do
  json.partial! 'agent', formats: [:json], agent: conversation.assignee if conversation.try(:assignee).present?
end
