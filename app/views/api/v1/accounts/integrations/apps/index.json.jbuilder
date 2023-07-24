json.payload do
  json.array! @apps do |app|
    json.partial! 'api/v1/models/app', formats: [:json], resource: app
  end
end
