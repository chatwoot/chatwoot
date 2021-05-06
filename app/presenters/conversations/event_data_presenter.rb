class Conversations::EventDataPresenter < SimpleDelegator
  def push_data
    {
      additional_attributes: additional_attributes,
      can_reply: can_reply?,
      channel: inbox.try(:channel_type),
      id: display_id,
      inbox_id: inbox_id,
      contact_inbox: contact_inbox,
      messages: push_messages,
      meta: push_meta,
      status: status,
      unread_count: unread_incoming_messages.count,
      **push_timestamps
    }
  end

  private

  def push_messages
    [messages.chat.last&.push_event_data].compact
  end

  def push_meta
    { sender: contact.push_event_data, assignee: assignee&.push_event_data }
  end

  def push_timestamps
    {
      agent_last_seen_at: agent_last_seen_at.to_i,
      contact_last_seen_at: contact_last_seen_at.to_i,
      timestamp: last_activity_at.to_i
    }
  end
end
