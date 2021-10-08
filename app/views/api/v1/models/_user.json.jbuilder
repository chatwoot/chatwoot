json.access_token resource.access_token.token
json.account_id resource.active_account_user&.account_id
json.available_name resource.available_name
json.avatar_url resource.avatar_url
json.confirmed resource.confirmed?
json.display_name resource.display_name
json.email resource.email
json.hmac_identifier resource.hmac_identifier if GlobalConfig.get('CHATWOOT_INBOX_HMAC_KEY')['CHATWOOT_INBOX_HMAC_KEY'].present?
json.id resource.id
json.inviter_id resource.active_account_user&.inviter_id
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
    json.availability_status account_user.availability_status
    json.auto_offline account_user.auto_offline
  end
end
