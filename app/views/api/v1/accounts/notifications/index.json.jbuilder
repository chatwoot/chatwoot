json.data do
  json.meta do
    json.unread_count @unread_count
  end

  json.payload do
    json.array! @notifications do |notification|
      json.id notification.id
      json.notification_type notification.notification_type
      json.primary_actor notification.primary_actor&.push_event_data
      json.read_at notification.read_at
      json.secondary_actor notification.secondary_actor&.push_event_data
      json.user notification.user&.push_event_data
      json.created_at notification.created_at
    end
  end
end
