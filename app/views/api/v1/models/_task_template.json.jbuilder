json.id resource.id
json.key resource.key
json.title resource.title
json.description resource.description
json.default_priority resource.default_priority
json.default_due_offset_hours resource.default_due_offset_hours
json.metadata_schema resource.metadata_schema
json.checklist_template resource.checklist_template
json.active resource.active
json.position resource.position
json.default_team_id resource.default_team_id
if resource.default_team.present?
  json.default_team do
    json.id resource.default_team.id
    json.name resource.default_team.name
  end
end
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
