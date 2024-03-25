json.array! @applied_slas do |applied_sla|
  json.id applied_sla.id
  json.sla_policy_id applied_sla.sla_policy_id
  json.conversation_id applied_sla.conversation_id
  json.sla_status applied_sla.sla_status
  json.created_at applied_sla.created_at
  json.updated_at applied_sla.updated_at
  json.conversation do
    json.partial! 'api/v1/models/conversation', conversation: applied_sla.conversation
  end
  json.sla_events applied_sla.sla_events do |sla_event|
    json.partial! 'api/v1/models/sla_event', formats: [:json], sla_event: sla_event
  end
end
