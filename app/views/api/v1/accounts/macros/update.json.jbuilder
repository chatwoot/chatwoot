json.payload do
  json.partial! 'api/v1/models/macro', formats: [:json], macro: @macro
end
