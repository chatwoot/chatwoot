contact_points = contact.contact_point_data

json.email contact.email
json.id contact.id
json.name contact.name
json.phone_number contact.phone_number
json.additional_emails contact_points[:additional_emails]
json.email_addresses contact_points[:email_addresses]
json.additional_phones contact_points[:additional_phones]
json.phone_numbers contact_points[:phone_numbers]
json.identifier contact.identifier
json.additional_attributes contact.additional_attributes
json.last_activity_at contact.last_activity_at&.to_i
