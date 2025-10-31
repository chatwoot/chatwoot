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
    min_count = counts.values.min
    least_busy_agents = counts.select { |_id, count| count == min_count }.keys
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
    @allowed_online_agent_ids ||= online_ids & allowed_ids
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

  # def round_robin_manage_service
  #   @round_robin_manage_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  # end

  # def round_robin_key
  #   format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  # end
end
