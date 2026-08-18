json.id resource.id
json.conversation_id resource.conversation.display_id
json.account_id resource.account_id
json.subject resource.subject
json.ticket_type resource.ticket_type
json.status_category resource.status_category
json.waiting_on resource.waiting_on
json.waiting_note resource.waiting_note
json.due_at resource.due_at
json.closed_at resource.closed_at
json.created_by_id resource.created_by_id
json.open_tasks_count resource.open_tasks_count
json.created_at resource.created_at
json.updated_at resource.updated_at

json.tasks do
  json.array! resource.ticket_tasks do |task|
    json.partial! 'api/v1/models/ticket_task', formats: [:json], resource: task
  end
end
