json.array! @assistants do |assistant|
  json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: assistant
end
