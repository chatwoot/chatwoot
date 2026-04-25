json.id card.id
json.kanban_column_id card.kanban_column_id
json.kanban_board_id card.kanban_board_id
json.position card.position
json.potential_value card.potential_value
json.notes card.notes
json.created_by_id card.created_by_id

json.contact do
  json.id card.contact.id
  json.name card.contact.name
  json.phone_number card.contact.phone_number
  json.email card.contact.email
  json.avatar_url card.contact.avatar_url
end
