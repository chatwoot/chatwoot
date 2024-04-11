json.id @contact.id
json.name @contact.name
json.email @contact.email
json.has_email @contact.email.present?
json.phone_number @contact.phone_number
