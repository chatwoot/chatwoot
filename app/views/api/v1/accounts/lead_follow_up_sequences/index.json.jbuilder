json.array! @sequences do |sequence|
  json.id sequence.id
  json.name sequence.name
  json.description sequence.description
  json.active sequence.active
  json.inbox_id sequence.inbox_id
  json.inbox do
    json.id sequence.inbox.id
    json.name sequence.inbox.name
  end
  json.trigger_conditions sequence.trigger_conditions
  json.steps sequence.steps
  json.settings sequence.settings
  json.stats sequence.stats
  json.metadata sequence.metadata
  json.created_at sequence.created_at
  json.updated_at sequence.updated_at
end
