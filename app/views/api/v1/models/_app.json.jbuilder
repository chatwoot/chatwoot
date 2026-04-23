json.id resource.id
json.name resource.name
json.description resource.description
json.short_description resource.short_description.presence
json.enabled resource.enabled?(@current_account)

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
