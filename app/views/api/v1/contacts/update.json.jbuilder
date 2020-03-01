json.payload do
  json.id @contact.id
  json.name @contact.name
  json.email @contact.email
  json.phone_number @contact.phone_number
  json.thumbnail @contact.avatar_url
  json.additional_attributes @contact.additional_attributes
end
