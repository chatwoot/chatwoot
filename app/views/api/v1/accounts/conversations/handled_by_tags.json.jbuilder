json.array! @tags do |tag|
  json.handled_by tag.handled_by
  json.created_at tag.created_at
  json.current_user_id tag.current_user&.id
  json.current_user_name tag.current_user&.name
  json.current_user_email tag.current_user&.email
end