json.payload do
  json.array! @notes do |note|
    json.partial! 'api/v1/models/note', formats: [:json], resource: note
    json.contact do
      json.partial! 'api/v1/models/contact', formats: [:json], resource: note.contact
    end
  end
end
