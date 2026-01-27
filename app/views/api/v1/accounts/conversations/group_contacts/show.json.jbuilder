json.meta do
  json.count @total_count
  json.current_page @current_page.to_i
end

json.payload @group_contacts do |group_contact|
  json.partial! 'api/v1/models/contact', format: :json, resource: group_contact.contact
end
