json.payload do
  json.array! @data_imports do |data_import|
    json.partial! 'api/v1/accounts/data_imports/data_import', formats: [:json], data_import: data_import
  end
end
