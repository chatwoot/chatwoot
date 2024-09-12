json.array! @custom_apis do |custom_api|
  json.partial! 'api/v1/models/custom_api', formats: [:json], resource: custom_api
end
