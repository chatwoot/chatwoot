json.payload do
  json.array! @contacts do |contact|
    json.id contact.id
    json.name contact.name
    json.phone_number contact.phone_number
  end
end
