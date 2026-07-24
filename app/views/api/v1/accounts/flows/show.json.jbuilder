json.payload do
  json.partial! 'api/v1/models/flow', formats: [:json], resource: @flow
end
