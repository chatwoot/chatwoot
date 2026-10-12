json.extract! whatsapp_interactive_preset, :id, :name, :interactive_type, :schema_version, :definition, :created_at, :updated_at

json.creator do
  if whatsapp_interactive_preset.creator_active?
    json.id whatsapp_interactive_preset.created_by_id
    json.name whatsapp_interactive_preset.created_by.name
  else
    json.id nil
    json.name 'Former agent'
  end
end

json.permissions do
  json.update policy(whatsapp_interactive_preset).update?
  json.delete policy(whatsapp_interactive_preset).destroy?
end
