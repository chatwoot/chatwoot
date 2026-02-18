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
json.timezone resource.current_account_user&.timezone
json.phone_number resource.phone_number
json.current_account_user_id resource.current_account_user.id
json.crm_external_id resource.current_account_user&.crm_external_id
json.crm_role resource.current_account_user&.crm_role
json.crm_synced_at resource.current_account_user&.crm_synced_at
json.responsible_id resource.current_account_user&.responsible_id
json.responsible_name resource.current_account_user&.responsible&.user&.name
json.location_id resource.current_account_user&.location_id
json.location_name resource.current_account_user&.location&.name

json.working_hours resource.current_account_user&.working_hours do |wh|
  json.partial! 'api/v1/models/working_hours', resource: wh
end
