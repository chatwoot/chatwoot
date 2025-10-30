json.payload do
  json.array! @appointments do |appointment|
    json.id appointment.id
    json.location appointment.location
    json.description appointment.description
    json.start_time appointment.start_time
    json.end_time appointment.end_time
    json.assisted appointment.assisted
    json.contact_id appointment.contact_id
    if appointment.contact.present?
      json.contact do
        json.id appointment.contact.id
        json.name appointment.contact.name
        json.email appointment.contact.email
        json.phone_number appointment.contact.phone_number
      end
    else
      json.contact nil
    end
    json.created_at appointment.created_at
    json.updated_at appointment.updated_at
    json.qr_code_url appointment.qr_code.attached? ? url_for(appointment.qr_code) : nil
  end
end

json.meta do
  json.count @appointments_count
  json.current_page @appointments.current_page
  json.total_pages @appointments.total_pages
end
