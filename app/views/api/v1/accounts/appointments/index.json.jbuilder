json.array! @appointments do |appointment|
  json.id appointment.id
  json.location appointment.location
  json.description appointment.description
  json.start_time appointment.start_time
  json.end_time appointment.end_time
  json.contact_id appointment.contact_id
  json.contact do
    json.id appointment.contact.id
    json.name appointment.contact.name
    json.email appointment.contact.email
    json.phone_number appointment.contact.phone_number
  end
  json.created_at appointment.created_at
  json.updated_at appointment.updated_at
  json.qr_code_url appointment.qr_code.attached? ? url_for(appointment.qr_code) : nil
end
