class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def perform
    assignee = find_assignee
    return unless assignee

    conversation.update!(assignee: assignee)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("AutoAssignment failed for Conversation #{conversation.id}: #{e.message}")
  end

  def find_assignee
    ids = allowed_online_agent_ids
    return if ids.blank?

    counts = active_chat_counts_for(ids)

    available_ids = filter_agents_below_limit(ids, counts)

    return if available_ids.blank?

    min_count = counts.slice(*available_ids).values.min
    least_busy_agents = counts.select { |id, count| available_ids.include?(id) && count == min_count }.keys
    selected_id = pick_least_recent_assigned(least_busy_agents)

    User.find_by(id: selected_id)
  end

  private

  def online_agent_ids
    @online_agent_ids ||= begin
      agents = OnlineStatusTracker.get_available_users(conversation.account_id)
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
      .where(assignee_id: agent_ids)
      .where.not(status: :resolved)
      .group(:assignee_id)
      .count
      .tap do |hash|
        agent_ids.each { |id| hash[id] ||= 0 }
      end
  end

  def pick_least_recent_assigned(agent_ids)
    return agent_ids.sample if agent_ids.size == 1

    last_closed_times = last_closed_chat_times_for(agent_ids)
    agent_ids.min_by { |id| last_closed_times[id] || Time.zone.at(0) }
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

  # def round_robin_manage_service
  #   @round_robin_manage_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  # end

  # def round_robin_key
  #   format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  # end
end
