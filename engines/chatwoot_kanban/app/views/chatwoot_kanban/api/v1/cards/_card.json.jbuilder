json.id card.id
json.column_id card.column_id
json.title card.title
json.description card.description
json.position card.position
json.priority card.priority
json.due_at card.due_at&.iso8601
json.assignee_id card.assignee_id
json.created_by_id card.created_by_id
json.conversation_id card.conversation_id
json.metadata card.metadata
json.archived card.archived?
json.archived_at card.archived_at&.iso8601
json.created_at card.created_at.iso8601
json.updated_at card.updated_at.iso8601

# Aggregates (kept cheap — uses size which respects loaded associations)
json.checklist_progress card.checklist_progress
json.checklist_total card.checklist_items.size
json.comments_count card.comments.size

json.labels card.labels do |label|
  json.id label.id
  json.name label.name
  json.color label.color
end

if card.conversation_id.present? && card.conversation
  json.conversation do
    json.id card.conversation.id
    json.display_id card.conversation.display_id
    json.status card.conversation.status
    json.inbox_id card.conversation.inbox_id
  end
end
