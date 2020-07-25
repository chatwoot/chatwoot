class Conversations::EventDataPresenter < SimpleDelegator
  def lock_data
    { id: display_id, locked: locked? }
  end

  def push_data
    {
      additional_attributes: additional_attributes,
      id: display_id,
      inbox_id: inbox_id,
      messages: push_messages,
      channel: inbox.try(:channel_type),
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
    { sender: contact.push_event_data, assignee: assignee }
  end

  def push_timestamps
    {
      agent_last_seen_at: agent_last_seen_at.to_i,
      user_last_seen_at: user_last_seen_at.to_i,
      timestamp: created_at.to_i
    }
  end
end
