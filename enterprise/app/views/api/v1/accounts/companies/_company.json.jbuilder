json.id company.id
json.name company.name
json.contacts_count company.contacts_count
json.domain company.domain
json.description company.description
json.avatar_url company.avatar_url
json.account_owner_id company.account_owner_id
if company.account_owner.present?
  json.account_owner do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: company.account_owner
  end
else
  json.account_owner nil
end
json.created_at company.created_at
json.updated_at company.updated_at
