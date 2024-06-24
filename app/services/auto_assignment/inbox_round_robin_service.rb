class AutoAssignment::InboxRoundRobinService
  pattr_initialize [:inbox!]

  # called on inbox delete
  def clear_queue
    ::Redis::Alfred.delete(round_robin_key)
  end

  # called on inbox member create
  # called on inbox team create
  def add_agent_to_queue(user_id)
    ::Redis::Alfred.lpush(round_robin_key, user_id)
  end

  # called on inbox member delete
  # called on inbox team delete
  def remove_agent_from_queue(user_id)
    ::Redis::Alfred.lrem(round_robin_key, user_id)
  end

  def reset_queue
    clear_queue
    add_agent_to_queue(fetch_inbox_agents)
  end

  # end of queue management functions

  # allowed member ids = [assignable online agents supplied by the assignement service]
  # the values of allowed member ids should be in string format
  def available_agent(allowed_agent_ids: [])
    reset_queue unless validate_queue?
    user_id = get_member_from_allowed_agent_ids(allowed_agent_ids)
    return nil if user_id.blank?

    user = inbox.inbox_members.find_by(user_id: user_id)&.user
    return user if user.present?

    user = get_member_from_teams(user_id)
    return user if user.present?
  end

  private

  def get_member_from_allowed_agent_ids(allowed_agent_ids)
    return nil if allowed_agent_ids.blank?

    user_id = queue.intersection(allowed_agent_ids).pop
    pop_push_to_queue(user_id)
    user_id
  end

  def pop_push_to_queue(user_id)
    return if user_id.blank?

    remove_agent_from_queue(user_id)
    add_agent_to_queue(user_id)
  end

  def validate_queue?
    unique_agent_ids = fetch_inbox_agents

    return true if unique_agent_ids.sort == queue.map(&:to_i).sort
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end

  def fetch_inbox_agents
    inbox_members_ids = inbox.inbox_members.map(&:user_id).sort
    inbox_teams_agents_ids = inbox.inbox_teams.flat_map do |inbox_team|
      Team.find(inbox_team.team_id).members.map(&:id)
    end
    (inbox_members_ids + inbox_teams_agents_ids).uniq
  end

  def get_member_from_teams(user_id)
    user = nil
    inbox.inbox_teams.find do |inbox_team|
      user = Team.find(inbox_team.team_id).members.find(user_id)
      break if user.present?
    end
    return user if user.present?
  end
end
