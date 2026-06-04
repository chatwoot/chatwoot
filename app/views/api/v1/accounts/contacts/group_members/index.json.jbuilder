json.payload do
  json.array! @group_members do |member|
    json.id member.id
    json.role member.role
    json.is_active member.is_active
    json.group_contact_id member.group_contact_id
    json.contact do
      json.id member.contact.id
      json.name member.contact.name
      json.phone_number member.contact.phone_number
      json.identifier member.contact.identifier
      json.thumbnail member.contact.avatar_url
    end
  end
end

json.meta do
  json.total_count @total_count
  json.page @page
  json.per_page @per_page
  json.inbox_phone_number @inbox_phone_number
  json.is_inbox_admin @is_inbox_admin
end
