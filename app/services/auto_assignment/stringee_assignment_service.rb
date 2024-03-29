class AutoAssignment::StringeeAssignmentService
  pattr_initialize [:inbox!]

  # allowed member ids = [assignable online agents supplied by the assignement service]
  # the values of allowed member ids should be in string format
  def perform
    reset_queue unless validate_queue?

    user_ids = members_from_allowed_agent_ids
    User.where(id: user_ids) if user_ids.present?
  end

  private

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(inbox.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_agent_ids
    inbox.member_ids_with_assignment_capacity
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    @allowed_online_agent_ids ||= online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def members_from_allowed_agent_ids
    return nil if allowed_online_agent_ids.blank?

    queue.intersection(allowed_online_agent_ids)
  end

  def validate_queue?
    return true if inbox.inbox_members.map(&:user_id).sort == queue.map(&:to_i).sort
  end

  def clear_queue
    ::Redis::Alfred.delete(round_robin_key)
  end

  def reset_queue
    clear_queue
    add_agent_to_queue(inbox.inbox_members.map(&:user_id))
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end
end
