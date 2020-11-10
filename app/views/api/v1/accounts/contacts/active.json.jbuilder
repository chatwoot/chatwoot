json.meta do
  json.count @contacts_count
  json.current_page @current_page
end

json.payload do
  json.array! @contacts do |contact|
    json.partial! 'api/v1/models/contact.json.jbuilder', resource: contact, with_contact_inboxes: true
  end
end
