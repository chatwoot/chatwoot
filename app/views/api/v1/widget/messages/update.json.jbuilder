if @contact
  json.contact do
    json.has_email @contact.email.present?
    json.has_name @contact.name.present?
    json.has_phone_number @contact.phone_number.present?
  end
end
