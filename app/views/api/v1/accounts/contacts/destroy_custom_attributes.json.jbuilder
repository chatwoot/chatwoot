json.payload do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: @contact, with_contact_inboxes: true, with_email_addresses: true
end
