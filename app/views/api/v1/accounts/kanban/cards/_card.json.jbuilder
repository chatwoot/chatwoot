json.id card.id
json.kanban_column_id card.kanban_column_id
json.kanban_board_id card.kanban_board_id
json.position card.position
json.potential_value card.potential_value
json.notes card.notes
json.created_by_id card.created_by_id
json.created_at card.created_at

json.contact do
  json.id card.contact.id
  json.name card.contact.name
  json.phone_number card.contact.phone_number
  json.email card.contact.email
  json.avatar_url card.contact.avatar_url
end

json.activities card.activities do |activity|
  json.id activity.id
  json.created_at activity.created_at
  json.user_name activity.user&.name
  json.from_column_name activity.from_column&.name
  json.to_column_name activity.to_column&.name
end

json.schedules card.schedules.select(&:pending?) do |schedule|
  json.id schedule.id
  json.title schedule.title
  json.description schedule.description
  json.scheduled_at schedule.scheduled_at
  json.status schedule.status
  json.created_by_name schedule.created_by&.name
end
