json.access_token resource.access_token.token
json.account_id resource.active_account_user&.account_id
json.available_name resource.available_name
json.avatar_url resource.avatar_url
json.confirmed resource.confirmed?
json.display_name resource.display_name
json.azar_display_name resource.azar_display_name
json.mono_display_name resource.mono_display_name
json.gbits_display_name resource.gbits_display_name
json.message_signature resource.message_signature
json.azar_message_signature resource.azar_message_signature
json.mono_message_signature resource.mono_message_signature
json.gbits_message_signature resource.gbits_message_signature
json.email resource.email
json.id resource.id
json.name resource.name
json.provider resource.provider
json.pubsub_token resource.pubsub_token
json.custom_attributes resource.custom_attributes if resource.custom_attributes.present?
json.role resource.active_account_user&.role
json.ui_settings resource.ui_settings
json.uid resource.uid
json.accounts do
  json.array! resource.account_users do |account_user|
    json.id account_user.account_id
    json.name account_user.account.name
    json.active_at account_user.active_at
    json.role account_user.role
  end
end
