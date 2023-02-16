json.call(resource.params, *resource.params.keys)
json.name resource.name
json.description resource.description
json.enabled resource.enabled?(@current_account)
json.action resource.action
json.button resource.action
json.hooks do
  json.array! @current_account.hooks.where(app_id: resource.id) do |hook|
    json.partial! 'api/v1/models/hook', formats: [:json], resource: hook
  end
end
