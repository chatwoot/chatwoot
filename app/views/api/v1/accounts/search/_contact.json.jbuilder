json.email contact.email
json.id contact.id
json.name contact.name
json.phone_number contact.phone_number
json.identifier contact.identifier
json.additional_attributes contact.additional_attributes
json.last_activity_at contact.last_activity_at&.to_i
if defined?(with_email_addresses) && with_email_addresses.present?
  json.email_addresses do
    json.array! contact.contact_emails.order(primary: :desc, created_at: :asc) do |email_record|
      json.id email_record.id
      json.email email_record.email
      json.primary email_record.primary
    end
  end
end
