json.id company.id
json.name company.name
json.domain company.domain
json.description company.description
json.avatar company.avatar_url
json.contacts_count company.contacts_count
json.additional_attributes company.additional_attributes
json.custom_attributes company.custom_attributes
json.last_activity_at company.last_activity_at.to_i if company[:last_activity_at].present?
json.created_at company.created_at.to_i if company[:created_at].present?
json.updated_at company.updated_at.to_i if company[:updated_at].present?
