# The agents a call rings: those online, taking calls and able to open the conversation.
# Socket presence is not consulted, since a locked phone is exactly what a ring push is for.
# A call rings only free agents, those not on a call or in wrap-up time, and picks them
# up as they free up, since each ring step asks again; the assignee rings alone first, then
# everyone or the longest idle agent.
#
# The call's team sets who everyone is, by its widen_calls setting: every agent in the inbox (the
# default), only the team's members, or nobody past the assignee. The call's team is the
# assignee's team when they are in exactly one team, else the conversation's team; a call with no
# team rings every agent in the inbox. An assignee outside the call's team counts as no assignee,
# so the whole team rings, and a team that rings nobody past its assignee rings as its members
# do when the call has no assignee in it.
# A team that rings nobody past its assignee holds a Twilio call for them alone, so the caller
# hears the missed-call message when the assignee cannot ring. A WhatsApp call has no such
# message and would ring nobody until it times out, so it holds for the assignee only while they
# can ring, and otherwise rings the team's members.
class Voice::RingRecipients
  pattr_initialize [:inbox!, :conversation!, :dismissed_user_ids]

  # How far back routing looks for each agent's last call
  IDLE_WINDOW = 1.day

  # The agents the ring starts with
  def agents
    return held_agents if assignee_held?
    return [assignee] if assignee_first?
    return ordered.first(1) if inbox.channel.sequential_ringing?

    available
  end

  # The agents a ring for everyone at once adds next: the free agents it has not rung
  def next_group(rung_ids)
    return [] if assignee_held? || team_changed?(rung_ids)

    available.reject { |user| rung_ids.include?(user.id) }
  end

  # The agent a ring in turn adds next: the first in routing order it has not rung
  def next_agent(rung_ids)
    return if assignee_held? || team_changed?(rung_ids)

    ordered.find { |user| rung_ids.exclude?(user.id) }
  end

  # Nobody who could answer is online, as opposed to everyone being busy, when the caller waits.
  # A call held for its assignee has nobody else to wait for, so it ends at once when they cannot ring.
  def nobody_online?
    return !assignee_rings_now? if assignee_held?

    eligible.empty?
  end

  private

  def assignee = conversation.assignee

  def assignable = (@assignable ||= inbox.assignable_agents.to_a)

  # A call whose team rings only its members leaves everyone else out of the pool
  def eligible
    @eligible ||= openers(team_scoped? ? team_pool : assignable).reject { |user| dismissed_user_ids.to_a.include?(user.id) }
  end

  # Agents on a call or in wrap-up time are left out until they free up
  def available
    @available ||= eligible.reject { |user| on_call_ids.include?(user.id) || in_cooldown?(user) }
  end

  # The assignee first, then the free agents by idle time, an agent with no call in the day first
  def ordered
    @ordered ||= begin
      first = assignee_first? ? [assignee] : []
      first + (available - first).sort_by { |user| last_calls[user.id]&.ended_at.to_i }
    end
  end

  # The assignee rings first even in wrap-up time, so a customer who calls straight back stays
  # with them
  def assignee_first?
    inbox.channel.assignee_rings_first? && assignee_rings_now?
  end

  # The assignee can ring now: eligible, not on another call, and a member of the call's team
  # when that team rings only its members
  def assignee_rings_now?
    (!team_scoped? || assignee_in_team?) && eligible.include?(assignee) && on_call_ids.exclude?(assignee.id)
  end

  # Resolving the conversation of the agent's last call ends their wrap-up time early
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

  # The team the call belongs to, read again at every ring step from the live conversation, so a
  # reassignment moves the next step. Nil when neither the assignee nor the conversation names one.
  def call_team
    return @call_team if defined?(@call_team)

    @call_team = assignee_team || conversation.team
  end

  # The assignee's team decides, unless they are in no team or in several
  def assignee_team
    return if assignee.blank?

    teams = assignee.teams.where(account_id: inbox.account_id).limit(2).to_a
    teams.first if teams.one?
  end

  # Who else rings when the assignee cannot take the call; a call with no team rings everyone
  def widening
    call_team&.widen_calls || 'inbox_agents'
  end

  # The call rings only its team's members, never the rest of the inbox
  def team_scoped?
    widening != 'inbox_agents'
  end

  def team_member_ids
    @team_member_ids ||= call_team ? call_team.team_members.pluck(:user_id) : []
  end

  def team_pool
    assignable.select { |user| team_member_ids.include?(user.id) }
  end

  # An assignee outside the call's team (one in no team who dialled out, or moved off the team)
  # is treated as no assignee, so the whole team rings
  def assignee_in_team?
    call_team.present? && assignee.present? && team_member_ids.include?(assignee.id)
  end

  # The call rings its assignee alone and never widens, whatever the inbox's assignee-first
  # setting. A WhatsApp call is held only while the assignee can ring; see the class comment.
  def assignee_held?
    widening == 'assignee_only' && assignee_in_team? && (inbox.channel.is_a?(Channel::TwilioSms) || assignee_rings_now?)
  end

  def held_agents
    assignee_rings_now? ? [assignee] : []
  end

  # One team per call: once a call has rung someone outside the team it now belongs to (the
  # conversation was reassigned mid-ring), it adds nobody, so it never rings two teams
  def team_changed?(rung_ids)
    team_scoped? && rung_ids.any? { |id| team_member_ids.exclude?(id) }
  end
end
