json.id resource.id
json.title resource.title
json.description resource.description
json.status resource.status
json.priority resource.priority
json.metadata resource.metadata
json.due_at resource.due_at&.to_i
json.claimed_at resource.claimed_at&.to_i
json.started_at resource.started_at&.to_i
json.completed_at resource.completed_at&.to_i
json.conversation_id resource.conversation_id
json.task_template_id resource.task_template_id
json.assigned_to_id resource.assigned_to_id
json.team_id resource.team_id
json.depends_on_task_id resource.depends_on_task_id
json.source_message_id resource.source_message_id
json.account_id resource.account_id

if resource.conversation.present?
  json.conversation do
    json.id resource.conversation.display_id
    json.contact_name resource.conversation.contact&.name
  end
end

if resource.created_by.present?
  json.created_by do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.created_by
  end
end

if resource.assigned_to.present?
  json.assigned_to do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: resource.assigned_to
  end
end

if resource.team.present?
  json.team do
    json.id resource.team.id
    json.name resource.team.name
  end
end

if resource.task_template.present?
  json.task_template do
    json.id resource.task_template.id
    json.key resource.task_template.key
    json.title resource.task_template.title
    json.metadata_schema resource.task_template.metadata_schema
  end
end

if resource.source_message.present?
  json.source_message do
    json.partial! 'api/v1/models/message', message: resource.source_message
  end
end

json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i

json.events resource.events.sort_by(&:created_at) do |event|
  json.id event.id
  json.event_type event.event_type
  json.metadata event.metadata
  json.created_at event.created_at.to_i
  if event.user.present?
    json.user do
      json.partial! 'api/v1/models/agent', formats: [:json], resource: event.user
    end
  end
end
