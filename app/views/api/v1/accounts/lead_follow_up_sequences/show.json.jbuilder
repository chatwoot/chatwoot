json.id @sequence.id
json.name @sequence.name
json.description @sequence.description
json.active @sequence.active
json.inbox_id @sequence.inbox_id
if @sequence.inbox
  json.inbox do
    json.id @sequence.inbox.id
    json.name @sequence.inbox.name
    json.channel_type @sequence.inbox.channel_type
  end
else
  json.inbox nil
end
json.source_type @sequence.source_type
json.source_config @sequence.source_config
json.first_contact_config @sequence.first_contact_config
json.trigger_conditions @sequence.trigger_conditions
json.steps @sequence.steps
json.settings @sequence.settings
json.stats @sequence.stats
json.metadata @sequence.metadata
json.created_at @sequence.created_at
json.updated_at @sequence.updated_at
