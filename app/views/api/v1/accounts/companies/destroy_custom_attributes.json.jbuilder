json.payload do
  json.partial! 'api/v1/models/company', formats: [:json], resource: @company
end
