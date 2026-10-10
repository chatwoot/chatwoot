if conversation.ai_assignee.is_a?(Captain::Assistant)
  json.assignee do
    json.partial! 'api/v1/models/captain/assistant_slim', formats: [:json], resource: conversation.ai_assignee
  end
  json.assignee_type 'Captain::Assistant'
end
