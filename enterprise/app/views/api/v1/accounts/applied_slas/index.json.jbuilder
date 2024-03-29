json.payload do
  json.array! @applied_slas do |applied_sla|
    json.id applied_sla.id
    json.sla_policy_id applied_sla.sla_policy_id
    json.conversation_id applied_sla.conversation_id
    json.sla_status applied_sla.sla_status
    json.created_at applied_sla.created_at
    json.updated_at applied_sla.updated_at
    json.conversation do
      json.contact do
        json.name applied_sla.conversation.contact.name
      end
      json.labels applied_sla.conversation.cached_label_list
      json.assignee applied_sla.conversation.assignee
    end
    json.sla_events applied_sla.sla_events do |sla_event|
      json.partial! 'api/v1/models/sla_event', formats: [:json], sla_event: sla_event
    end
    json.sla_policy do
      json.partial! 'api/v1/models/sla_policy', sla_policy: applied_sla.sla_policy
    end
  end
end

json.meta do
  json.total_applied_slas @total_applied_slas
  json.current_page @current_page
end
