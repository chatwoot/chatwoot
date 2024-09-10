class AutoAssignment::StringeeAssignmentService
  pattr_initialize [:inbox!, :last_conversation]

  # allowed member ids = [assignable online agents supplied by the assignement service]
  # the values of allowed member ids should be in string format
  def perform
    reset_queue unless validate_queue?

    pop_push_to_left_queue(last_conversation&.assignee_id) if last_conversation&.assignee_id.present?

    user_ids = members_from_allowed_agent_ids
    return if user_ids.blank?

    order_by_clause = user_ids.map { |id| "WHEN #{id} THEN #{user_ids.index(id)}" }.join(' ')
    User.order(Arel.sql("CASE id #{order_by_clause} END")).where(id: user_ids)
  end

  def pop_push_to_right_queue(user_id)
    return unless queue.include?(user_id.to_s)

    remove_agent_from_queue(user_id)
    add_agent_to_right_queue(user_id)
  end

  private

  def inbox_members
    inbox.team.present? ? inbox.team.team_members : inbox.inbox_members
  end

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(inbox.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_agent_ids
    inbox.agents.ids
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def members_from_allowed_agent_ids
    return nil if allowed_online_agent_ids.blank?

    queue.intersection(allowed_online_agent_ids)
  end

  def validate_queue?
    return true if inbox_members.map(&:user_id).sort == queue.map(&:to_i).sort
  end

  def clear_queue
    ::Redis::Alfred.delete(round_robin_key)
  end

  def reset_queue
    clear_queue
    add_agent_to_left_queue(inbox_members.map(&:user_id))
  end

  def pop_push_to_left_queue(user_id)
    return unless queue.include?(user_id.to_s)

    remove_agent_from_queue(user_id)
    add_agent_to_left_queue(user_id)
  end

  def add_agent_to_left_queue(user_id)
    ::Redis::Alfred.lpush(round_robin_key, user_id)
  end

  def add_agent_to_right_queue(user_id)
    ::Redis::Alfred.rpush(round_robin_key, user_id)
  end

  def remove_agent_from_queue(user_id)
    ::Redis::Alfred.lrem(round_robin_key, user_id)
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end
end
