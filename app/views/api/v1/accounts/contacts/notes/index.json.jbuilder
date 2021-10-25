json.array! @notes do |note|
  json.partial! 'api/v1/models/note.json.jbuilder', resource: note
end
