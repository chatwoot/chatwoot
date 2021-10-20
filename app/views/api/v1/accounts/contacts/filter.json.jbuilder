json.array! @contacts do |contact|
  json.partial! 'api/v1/models/contact.json.jbuilder', resource: contact
end
