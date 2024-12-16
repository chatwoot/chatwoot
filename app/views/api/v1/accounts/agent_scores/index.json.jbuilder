json.array! @agent_scores do |agent_score|
  json.partial! 'api/v1/models/smart_action', formats: [:json], smart_action: agent_score
end