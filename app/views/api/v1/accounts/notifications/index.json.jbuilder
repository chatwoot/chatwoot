json.data do
  json.meta do
    json.unread_count @unread_count
    json.count @count
    json.current_page @current_page
  end

  json.payload do
    json.array! @notifications do |notification|
      json.id notification.id
      json.notification_type notification.notification_type
      json.push_message_title notification.push_message_title
      json.primary_actor_type notification.primary_actor_type
      json.primary_actor_id notification.primary_actor_id
      json.primary_actor notification.primary_actor&.push_event_data
      json.read_at notification.read_at
      json.secondary_actor notification.secondary_actor&.push_event_data
      json.user notification.user&.push_event_data
      json.created_at notification.created_at.to_i
    end
  end
end
