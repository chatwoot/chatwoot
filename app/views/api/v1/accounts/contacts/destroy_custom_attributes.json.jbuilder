json.payload do
  json.partial! 'api/v1/models/contact.json.jbuilder', resource: @contact, with_contact_inboxes: true
end
