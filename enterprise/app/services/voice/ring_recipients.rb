# The agents a call rings: those online, taking calls and able to open the conversation.
# Socket presence is not consulted, since a locked phone is exactly what a ring push is for.
# A Twilio call orders them for routing (free assignee, then longest idle, with agents in
# cooldown or on a call held back); a WhatsApp call rings the assignee or everyone.
class Voice::RingRecipients
  pattr_initialize [:inbox!, :conversation!, :dismissed_user_ids]

  # How far back routing looks for each agent's last call
  IDLE_WINDOW = 1.day

  # The agents the ring starts with
  def agents
    return whatsapp_agents unless inbox.channel.is_a?(Channel::TwilioSms)
    return ordered.first(1) if inbox.channel.sequential_ringing?
    return [assignee] if assignee_first?

    team
  end

  # The agents a ring for everyone at once reaches: the free ones outside cooldown, or every
  # eligible agent when there are none
  def team = eligible.reject { |user| deprioritized?(user) }.presence || eligible

  # The agents a ring for everyone at once adds next: the team it has not rung, and once it
  # rings the whole team, the agents it held back
  def next_group(rung_ids)
    unrung = ->(users) { users.reject { |user| rung_ids.include?(user.id) } }
    unrung.call(team).presence || unrung.call(eligible)
  end

  # The agent a ring in turn adds next: the first in routing order it has not rung
  def next_agent(rung_ids)
    ordered.find { |user| rung_ids.exclude?(user.id) }
  end

  private

  def assignee = conversation.assignee

  def assignable = (@assignable ||= inbox.assignable_agents.to_a)

  def whatsapp_agents
    openers(assignable.include?(assignee) ? [assignee] : assignable)
  end

  def eligible
    @eligible ||= openers(assignable).reject { |user| dismissed_user_ids.to_a.include?(user.id) }
  end

  def ordered
    @ordered ||= begin
      first = assignee_first? ? [assignee] : []
      first + (eligible - first).sort_by { |user| [deprioritized?(user) ? 1 : 0, last_calls[user.id]&.ended_at.to_i] }
    end
  end

  # The assignee rings first even in cooldown, so a customer who calls straight back stays with them
  def assignee_first? = eligible.include?(assignee) && on_call_ids.exclude?(assignee.id)

  def deprioritized?(user)
    (inbox.channel.prefer_free_agents? && on_call_ids.include?(user.id)) || in_cooldown?(user)
  end

  # Resolving the conversation of the agent's last call ends their cooldown early
  def in_cooldown?(user)
    cooldown = inbox.channel.call_cooldown_seconds
    return false unless cooldown.positive?

    last = last_calls[user.id]
    last.present? && last.ended_at.to_i > cooldown.seconds.ago.to_i && resolved_conversation_ids.exclude?(last.conversation_id)
  end

  def resolved_conversation_ids
    @resolved_conversation_ids ||= Conversation.where(id: last_calls.values.map(&:conversation_id)).resolved.pluck(:id)
  end

  # On a call, picking one up or dialing out. Bounded like last_calls, so a call whose end was
  # never reported stops counting after a day.
  def on_call_ids
    @on_call_ids ||= Call.active.where(account_id: inbox.account_id, accepted_by_agent_id: eligible.map(&:id), created_at: IDLE_WINDOW.ago..)
                         .distinct.pluck(:accepted_by_agent_id)
  end

  # Each eligible agent's latest answered call that has ended, however it ended, within the
  # day: an agent with none since is idle longer than anyone who has one
  def last_calls
    @last_calls ||= Call.where(account_id: inbox.account_id, status: Call::TERMINAL_STATUSES, accepted_by_agent_id: eligible.map(&:id),
                               created_at: IDLE_WINDOW.ago..)
                        .where.not(started_at: nil)
                        .select(:accepted_by_agent_id, :conversation_id, :meta)
                        .group_by(&:accepted_by_agent_id)
                        .transform_values { |calls| calls.max_by { |call| call.ended_at.to_i } }
  end

  def openers(users)
    online = AccountUser.where(account_id: inbox.account_id, user_id: users.map(&:id), availability: :online, accepts_calls: true)
                        .index_by(&:user_id)
    users.select { |user| online[user.id] && can_open_conversation?(user, online[user.id]) }
  end

  def can_open_conversation?(user, account_user)
    ConversationPolicy.new({ user: user, account: inbox.account, account_user: account_user }, conversation).show?
  end
end
