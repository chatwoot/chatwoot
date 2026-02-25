json.array! @notes do |note|
  json.partial! 'api/v1/models/note', formats: [:json], resource: note
end
