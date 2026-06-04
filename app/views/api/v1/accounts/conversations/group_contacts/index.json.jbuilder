json.meta do
  json.count @group_contacts.total_count
  json.current_page @group_contacts.current_page
end

json.payload do
  json.array! @group_contacts do |group_contact|
    json.id group_contact.id
    json.contact_id group_contact.contact_id
    json.participant_identifier participant_identifier(group_contact)
    json.contact do
      json.partial! 'api/v1/models/contact', formats: [:json], resource: group_contact.contact
    end
    json.metadata group_contact.metadata
  end
end
