json.payload do
  json.availability_status @contact.availability_status
  json.email @contact.email
  json.id @contact.id
  json.name @contact.name
  json.phone_number @contact.phone_number
  json.thumbnail @contact.avatar_url
end
