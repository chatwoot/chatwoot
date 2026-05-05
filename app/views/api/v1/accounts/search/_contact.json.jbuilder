json.email contact.email
json.id contact.id
json.name contact.name
json.phone_number contact.phone_number
json.identifier contact.identifier
json.additional_attributes contact.additional_attributes
json.last_activity_at contact.last_activity_at&.to_i
if defined?(with_email_addresses) && with_email_addresses.present?
  json.additional_emails contact.additional_emails
  json.email_addresses contact.all_emails
end
