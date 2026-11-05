json.id @contact.id
json.merge! @contact.widget_presence_data
json.widget_auth_token @widget_auth_token if @widget_auth_token.present?
