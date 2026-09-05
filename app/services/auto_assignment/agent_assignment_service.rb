class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    ids = allowed_online_agent_ids
    Rails.logger.debug { "AutoAssignment [conv=#{conversation.id}] online+allowed ids: #{ids}" }

    return if ids.blank?

    counts = active_chat_counts_for(ids)
    Rails.logger.debug { "AutoAssignment [conv=#{conversation.id}] load counts: #{counts}" }

    available_ids = filter_agents_below_limit(ids, counts)
    Rails.logger.debug { "AutoAssignment [conv=#{conversation.id}] available after limit filter: #{available_ids}" }

    return if available_ids.blank?

    min_count = counts.slice(*available_ids).values.min
    least_busy_agents = counts.select { |id, count| available_ids.include?(id) && count == min_count }.keys

    Rails.logger.debug { "AutoAssignment [conv=#{conversation.id}] least busy: #{least_busy_agents} (count=#{min_count})" }

    return User.find_by(id: least_busy_agents.first) if least_busy_agents.size == 1

    last_closed_times = last_closed_chat_times_for(least_busy_agents)
    selected_id = pick_least_recent_assigned(least_busy_agents, counts, last_closed_times)
    Rails.logger.debug { "AutoAssignment [conv=#{conversation.id}] selected by last_closed: #{selected_id}" }

    User.find_by(id: selected_id)
  end

  # Locks the row to serialize with concurrent assignment writers, then sets the assignee
  # on the in-memory conversation without saving. Called from the conversation's own
  # before_save so status and assignee commit as one change-set and both stay visible to
  # the after_commit callbacks. Returns the new assignee, or nil when nothing changed.
  def assign_under_lock
    locked = Conversation.lock.find_by(id: conversation.id)
    return unless locked

    discard_already_applied_status_change(locked)
    return unless reassignment_still_needed?(locked)

    new_assignee = find_assignee
    return unless new_assignee

    conversation.assignee_id = locked.assignee_id
    conversation.clear_attribute_changes([:assignee_id])
    conversation.assignee = new_assignee
  end

  def perform
    # Standalone assignment with its own save (create path). Write through conversation
    # itself so its already-registered after_commit callbacks actually fire.
    Conversation.transaction do
      conversation.save if assign_under_lock
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("AutoAssignment failed for Conversation #{conversation.id}: #{e.message}")
  end

  private

  # A concurrent writer may have committed the same status transition while we waited for
  # the lock; keeping our stale copy dirty would announce it a second time (duplicate
  # conversation.opened events, activities and reporting rows), so drop it and let the
  # save carry only changes that are genuinely ours.
  def discard_already_applied_status_change(locked_conversation)
    return unless conversation.will_save_change_to_status? && conversation.status == locked_conversation.status

    conversation.clear_attribute_changes([:status])
  end

  # Fields the in-flight save is writing commit at their pending value (e.g. bot_handoff!
  # clears the agent bot in the same save that opens), so the locked row only decides
  # fields this save leaves untouched — the ones a concurrent writer would win.
  def reassignment_still_needed?(locked_conversation)
    bot_source = conversation.will_save_change_to_assignee_agent_bot_id? ? conversation : locked_conversation
    return false if bot_source.assignee_agent_bot_id.present?

    assignee = conversation.will_save_change_to_assignee_id? ? conversation.assignee : locked_conversation.assignee
    assignee.blank? || locked_conversation.inbox.members.exclude?(assignee)
  end

  def online_agent_ids
    @online_agent_ids ||= begin
      agents = OnlineStatusTracker.get_available_users(conversation.account_id) || {}
      agents.select { |_id, status| status == 'online' }.keys
    end
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    online_ids = online_agent_ids.map(&:to_i)
    allowed_ids = allowed_agent_ids.map(&:to_i)
    @allowed_online_agent_ids ||= (online_ids & allowed_ids)
  end

  def active_chat_counts_for(agent_ids)
    Conversation
      .where(assignee_id: agent_ids, account_id: conversation.account_id)
      .where.not(status: :resolved)
      .group(:assignee_id)
      .count
      .tap do |hash|
        agent_ids.each { |id| hash[id] ||= 0 }
      end
  end

  def pick_least_recent_assigned(agent_ids, counts, last_closed_times)
    stats = agent_ids.map do |id|
      {
        id: id,
        active: counts[id] || 0,
        last_closed: last_closed_times[id] || Time.zone.at(0)
      }
    end

    sorted = stats.sort_by { |s| [s[:active], s[:last_closed]] }
    sorted.first[:id]
  end

  def last_closed_chat_times_for(agent_ids)
    Conversation
      .where(assignee_id: agent_ids, status: :resolved)
      .select('assignee_id, MAX(updated_at) AS last_closed_at')
      .group(:assignee_id)
      .pluck(:assignee_id, Arel.sql('MAX(updated_at)'))
      .to_h
  end

  def filter_agents_below_limit(agent_ids, counts)
    agent_ids.reject do |agent_id|
      agent_at_or_over_limit?(agent_id, counts)
    end
  end

  def agent_at_or_over_limit?(agent_id, counts)
    limit = effective_limit_for_agent(agent_id)
    return false if limit.nil?

    current = counts[agent_id] || 0
    current >= limit
  end

  def effective_limit_for_agent(agent_id)
    account = conversation.account
    account_user = AccountUser.find_by(account_id: account.id, user_id: agent_id)

    if account_user&.active_chat_limit_enabled? && account_user.active_chat_limit.present?
      Rails.logger.debug { "Using personal limit=#{account_user.active_chat_limit} for agent=#{agent_id}" }
      return account_user.active_chat_limit.to_i
    end

    if account.active_chat_limit_enabled? && account.active_chat_limit.present?
      Rails.logger.debug { "Using global limit=#{account.active_chat_limit} for agent=#{agent_id}" }
      return account.active_chat_limit.to_i
    end

    Rails.logger.debug { "No limit for agent=#{agent_id}" }
    nil
  end
end
