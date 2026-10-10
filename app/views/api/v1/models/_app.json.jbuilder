json.id resource.id
json.name resource.name
json.description resource.description
json.short_description resource.short_description.presence
cleanup_only = resource.id == 'stripe' && !resource.active?(@current_account)
json.enabled !cleanup_only && resource.enabled?(@current_account)
json.cleanup_only cleanup_only if resource.id == 'stripe'

if Current.account_user&.administrator?
  json.call(resource.params, *resource.params.keys)
  json.action resource.action
  json.button resource.action
end

json.hooks do
  json.array! @current_account.hooks.where(app_id: resource.id) do |hook|
    json.partial! 'api/v1/models/hook', formats: [:json], resource: hook
  end
end
