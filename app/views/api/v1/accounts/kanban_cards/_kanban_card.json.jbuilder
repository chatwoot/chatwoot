json.id kanban_card.id
json.position kanban_card.position
json.metadata kanban_card.metadata
json.kanban_board_id kanban_card.kanban_board_id
json.kanban_column_id kanban_card.kanban_column_id
json.conversation_id kanban_card.conversation_id
json.conversation_display_id kanban_card.conversation.display_id
json.conversation_status kanban_card.conversation.status
json.conversation_priority kanban_card.conversation.priority
json.last_activity_at kanban_card.conversation.last_activity_at.to_i if kanban_card.conversation.last_activity_at
json.contact do
  json.id kanban_card.conversation.contact_id
  json.name kanban_card.conversation.contact&.name
end
json.inbox do
  json.id kanban_card.conversation.inbox_id
  json.name kanban_card.conversation.inbox&.name
end
json.created_at kanban_card.created_at.to_i
json.updated_at kanban_card.updated_at.to_i
