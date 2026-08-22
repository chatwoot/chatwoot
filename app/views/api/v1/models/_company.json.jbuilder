json.id resource.id
json.name resource.name
json.contacts_count resource.contacts_count
json.domain resource.domain
json.description resource.description
json.custom_attributes resource.custom_attributes
json.avatar_url resource.avatar_url
json.last_activity_at resource.last_activity_at.to_i if resource[:last_activity_at].present?
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?
