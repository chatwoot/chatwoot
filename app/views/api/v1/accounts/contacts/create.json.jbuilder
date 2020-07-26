json.payload do
  json.contact do
    json.partial! 'api/v1/models/contact.json.jbuilder', resource: @contact
  end
  json.contact_inbox do
    json.inbox @contact_inbox&.inbox
    json.source_id @contact_inbox&.source_id
  end
end
