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
      if %w[
        assigned_conversation_new_message
        participating_conversation_new_message
        conversation_mention
      ].include? notification.notification_type
        json.primary_actor_type 'Conversation'
        json.primary_actor_id notification.conversation.id
        json.primary_actor notification.conversation.push_event_data
      else
        json.primary_actor_type notification.primary_actor_type
        json.primary_actor_id notification.primary_actor_id
        json.primary_actor notification.primary_actor.push_event_data
      end
      json.read_at notification.read_at
      # Secondary actor could be nil for cases like system assigning conversation
      json.secondary_actor notification.secondary_actor&.push_event_data
      json.user notification.user.push_event_data
      json.created_at notification.created_at.to_i
    end
  end
end
