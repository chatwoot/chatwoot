json.id @funnel_contact.id
json.funnel_id @funnel_contact.funnel_id
json.contact_id @funnel_contact.contact_id
json.column_id @funnel_contact.column_id
json.position @funnel_contact.position
json.contact do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: @funnel_contact.contact
end

