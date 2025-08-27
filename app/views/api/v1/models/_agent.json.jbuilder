json.id resource.id
# could be nil for a deleted agent hence the safe operator before account id
json.account_id Current.account&.id
json.availability_status resource.availability_status
json.auto_offline resource.auto_offline
json.confirmed resource.confirmed?
json.email resource.email
json.provider resource.provider
json.available_name resource.available_name
json.custom_attributes resource.custom_attributes if resource.custom_attributes.present?
json.name resource.name
json.role resource.role
json.thumbnail resource.avatar_url
json.custom_role_id resource.current_account_user&.custom_role_id if ChatwootApp.enterprise?
json.timezone resource.timezone

json.working_hours resource.working_hours do |wh|
  json.id wh.id
  json.day_of_week wh.day_of_week
  json.open_all_day wh.open_all_day
  json.closed_all_day wh.closed_all_day
  json.open_hour wh.open_hour
  json.open_minutes wh.open_minutes
  json.close_hour wh.close_hour
  json.close_minutes wh.close_minutes
  json.timezone resource.timezone if resource.respond_to?(:timezone)
end
