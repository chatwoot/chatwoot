json.call(resource.params, *resource.params.keys)
json.name resource.name
json.description resource.description
json.enabled resource.enabled?(@current_account)
json.button resource.action
json.hooks @current_account.hooks.where(app_id: resource.id)
