json.array! @group_contacts do |group_contact|
  json.partial! 'api/v1/models/contact', format: :json, resource: group_contact.contact
end
