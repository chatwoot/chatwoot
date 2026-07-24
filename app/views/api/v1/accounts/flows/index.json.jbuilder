json.payload do
  json.array! @flows do |flow|
    json.partial! 'api/v1/models/flow', formats: [:json], resource: flow
  end
end
