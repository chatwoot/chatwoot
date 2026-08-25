if conversation.assignee_type == 'Captain::Assistant'
  json.assignee do
    json.partial! 'api/v1/models/captain/assistant_slim', formats: [:json], resource: conversation.assigned_entity
  end
  json.assignee_type 'Captain::Assistant'
end
