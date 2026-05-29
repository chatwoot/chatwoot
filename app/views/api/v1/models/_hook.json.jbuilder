json.id resource.id
json.app_id resource.app_id
json.status resource.enabled?
json.inbox resource.inbox&.slice(:id, :name)
json.account_id resource.account_id
json.hook_type resource.hook_type

# fix: Redact sensitive integration secrets to prevent leakage to the frontend (#14042)
# even for administrators, raw API keys and private keys should not be exposed in the browser.
if Current.account_user&.administrator?
  json.settings resource.settings.except(
    'api_key', 
    'private_key', 
    'credentials', 
    'access_token', 
    'secret', 
    'token',
    'password'
  )
  json.reference_id resource.reference_id
end