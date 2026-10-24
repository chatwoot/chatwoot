json.payload do
  json.array! @data_imports do |data_import|
    json.partial! 'api/v1/accounts/data_imports/data_import', formats: [:json], data_import: data_import
  end
end
json.can_create_import !Current.account.data_imports.active_imports.exists?
json.integration_imports_enabled Current.account_user.administrator? && Current.account.feature_enabled?('data_import')
