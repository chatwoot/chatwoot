json.id @contact.id
json.name @contact.name
json.email @contact.email
json.has_email @contact.email.present?
json.phone_number @contact.phone_number
json.widget_auth_token @widget_auth_token if @widget_auth_token.present?
