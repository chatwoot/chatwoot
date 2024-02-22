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
      # TODO: front end assumes primary actor to be conversation. should fix in future
      json.primary_actor_type notification.primary_actor_type
      json.primary_actor_id notification.primary_actor_id
      json.primary_actor notification.primary_actor.push_event_data
      json.read_at notification.read_at
      # Secondary actor could be nil for cases like system assigning conversation
      json.secondary_actor notification.secondary_actor&.push_event_data
      json.user notification.user.push_event_data
      json.created_at notification.created_at.to_i
      json.last_activity_at notification.last_activity_at.to_i
      json.snoozed_until notification.snoozed_until
      json.meta notification.meta
    end
  end
end
