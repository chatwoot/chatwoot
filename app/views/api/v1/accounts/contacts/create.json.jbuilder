json.payload do
  json.contact do
    json.partial! 'api/v1/models/contact', formats: [:json], resource: @contact, with_contact_inboxes: true, with_email_addresses: true
  end
  json.contact_inbox do
    json.inbox @contact_inbox&.inbox
    json.source_id @contact_inbox&.source_id
  end
end
