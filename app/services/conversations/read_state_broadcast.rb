class Conversations::ReadStateBroadcast
  pattr_initialize [:conversation!]

  # Group recipients with identical read state; query receipts/messages once per event.
  def payloads(tokens, data, nested: false)
    users = User.where(pubsub_token: tokens).pluck(:id, :pubsub_token)
    payloads = recipient_groups(users).map do |(seen_at, count), recipients|
      state = { agent_last_seen_at: seen_at, unread_count: count }
      payload = nested ? data.merge(conversation: data.fetch(:conversation).merge(state)) : data.merge(state)
      [recipients.map(&:last), payload]
    end
    contact_tokens = tokens - users.map(&:last)
    payloads << [contact_tokens, data] if contact_tokens.any?
    payloads
  end

  private

  def recipient_groups(users)
    receipts = conversation.conversation_read_states.where(user_id: users.map(&:first)).pluck(:user_id, :last_seen_at).to_h
    incoming_times = conversation.messages.incoming.where(account_id: conversation.account_id)
                                 .order(created_at: :desc).limit(10).pluck(:created_at)
    users.group_by do |user_id, _token|
      seen_at = receipts[user_id] || conversation.read_baseline_at
      count = incoming_times.count { |created_at| seen_at.nil? || created_at > seen_at }
      [seen_at.to_i, count]
    end
  end
end
