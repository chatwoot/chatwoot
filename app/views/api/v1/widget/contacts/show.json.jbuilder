json.id @contact.id
json.has_email @contact.email.present?
json.has_name @contact.name.present?
json.has_phone_number @contact.phone_number.present?
json.identifier @contact.identifier
json.source_id @contact.contact_inboxes.first&.source_id
