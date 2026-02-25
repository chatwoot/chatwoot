json.payload do
  json.array! @macros do |macro|
    json.partial! 'api/v1/models/macro', formats: [:json], macro: macro
  end
end
