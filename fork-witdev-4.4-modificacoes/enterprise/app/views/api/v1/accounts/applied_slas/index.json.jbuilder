json.payload do
  json.array! @applied_slas do |applied_sla|
    json.applied_sla applied_sla.push_event_data
    json.conversation do
      conversation = applied_sla.conversation
      json.id conversation.id
      json.contact do
        json.name conversation.contact.name if conversation.contact
      end
      json.labels conversation.cached_label_list
      json.assignee conversation.assignee.push_event_data if conversation.assignee
    end
    json.sla_events applied_sla.sla_events do |sla_event|
      json.partial! 'api/v1/models/sla_event', formats: [:json], sla_event: sla_event
    end
  end
end

json.meta do
  json.count @count
  json.current_page @current_page
end
