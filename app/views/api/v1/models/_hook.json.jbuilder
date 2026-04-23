json.id resource.id
json.app_id resource.app_id
json.status resource.enabled?
json.inbox resource.inbox&.slice(:id, :name)
json.account_id resource.account_id
json.hook_type resource.hook_type

if Current.account_user&.administrator?
  app = Integrations::App.find(id: resource.app_id)
  visible_keys = app&.visible_properties
  json.settings visible_keys.present? ? resource.settings&.select { |key, _| visible_keys.include?(key.to_s) } : resource.settings
end
json.reference_id resource.reference_id if Current.account_user&.administrator?
