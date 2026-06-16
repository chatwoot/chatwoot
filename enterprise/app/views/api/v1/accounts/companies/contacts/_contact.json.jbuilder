json.partial! 'api/v1/models/contact', formats: [:json], resource: contact, with_contact_inboxes: false
json.company_id contact.company_id
json.linked_to_current_company contact.company_id == @company.id
if contact.company.present?
  json.company do
    json.id contact.company_id
    json.name contact.company.name
  end
else
  json.company nil
end
