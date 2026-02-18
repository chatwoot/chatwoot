json.payload do
  json.array! @appointments do |appointment|
    json.id appointment.id
    json.appointment_type appointment.appointment_type
    json.scheduled_at appointment.scheduled_at
    json.ended_at appointment.ended_at
    json.status appointment.status
    json.owner_id appointment.owner_id
    json.location appointment.location
    json.phone_number appointment.phone_number
    json.meeting_url appointment.meeting_url
    json.description appointment.description
    json.contact_id appointment.contact_id
    json.inbox_id appointment.inbox_id
    json.conversation_id appointment.conversation_id
    json.started_at appointment.started_at
    json.duration_minutes appointment.duration_minutes
    json.participants appointment.participants
    json.additional_attributes appointment.additional_attributes
    json.external_ids appointment.external_ids

    if appointment.contact.present?
      json.contact do
        json.id appointment.contact.id
        json.name appointment.contact.name
        json.email appointment.contact.email
        json.phone_number appointment.contact.phone_number
        json.thumbnail appointment.contact.avatar_url
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
