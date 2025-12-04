json.array! @user_assignments do |user_assignment|
  json.id user_assignment.id
  json.active user_assignment.active
  json.template do
    json.id user_assignment.advanced_email_template.id
    json.name user_assignment.advanced_email_template.name
    json.friendly_name user_assignment.advanced_email_template.friendly_name
    json.description user_assignment.advanced_email_template.description
    json.template_type user_assignment.advanced_email_template.template_type
  end
  json.created_at user_assignment.created_at
  json.updated_at user_assignment.updated_at
end
