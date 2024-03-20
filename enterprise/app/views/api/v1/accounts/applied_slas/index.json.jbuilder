json.array! @sla_responses do |sla_response|
  json.id sla_response.id
  json.sla_policy_id sla_response.sla_policy_id
  json.conversation_id sla_response.conversation_id
  json.sla_status sla_response.sla_status
  json.created_at sla_response.created_at
  json.updated_at sla_response.updated_at
  json.conversation do
    json.partial! 'api/v1/models/conversation', conversation: sla_response.conversation
  end
  json.sla_events sla_response.sla_events do |sla_event|
    json.partial! 'api/v1/models/sla_event', formats: [:json], sla_policy: sla_event
  end
end
