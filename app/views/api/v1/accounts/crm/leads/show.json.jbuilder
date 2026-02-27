json.extract! @lead, :id, :title, :value, :priority, :expected_closing_at, :created_at, :updated_at, :crm_stage_id, :contact_id, :conversation_id, :user_id
json.contact do
  json.extract! @lead.contact, :id, :name, :email, :thumbnail
end
if @lead.user
  json.user do
    json.extract! @lead.user, :id, :name, :thumbnail
  end
end
