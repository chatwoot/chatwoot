json.id @contact.id
json.name @contact.name
json.email @contact.email
json.phone_number @contact.phone_number
json.pubsub_token @contact_inbox.pubsub_token
json.widget_auth_token @widget_auth_token if @widget_auth_token.present?
