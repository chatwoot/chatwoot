json.id resource.display_id
json.status resource.status
json.created_at resource.created_at.to_i
json.last_activity_at resource.last_activity_at.to_i
json.contact_last_seen_at resource.contact_last_seen_at.to_i
json.unread_count unread_count

if resource.assignee.present?
  json.assignee do
    json.name resource.assignee.available_name
    json.avatar_url resource.assignee.avatar_url
  end
end

if last_message.present?
  json.last_message do
    json.partial! 'api/v1/models/widget_message', resource: last_message
  end
end
