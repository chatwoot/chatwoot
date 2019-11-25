json.payload do
  json.array! @contacts do |contact|
    json.id contact.id
    json.name contact.name
    json.email contact.email
    json.phone_number contact.phone_number
    json.thumbnail contact.avatar.profile_thumb.url
  end
end
