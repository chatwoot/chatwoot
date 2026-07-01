json.array! @workflows do |workflow|
  json.id workflow.id
  json.name workflow.name
  json.description workflow.description
  json.trigger_event workflow.trigger_event
  json.active workflow.active
  json.created_at workflow.created_at.to_i
end
