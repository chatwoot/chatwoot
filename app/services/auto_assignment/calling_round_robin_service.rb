class AutoAssignment::CallingRoundRobinService
  pattr_initialize [:account!]

  # called on call_settings delete
  def clear_queue
    ::Redis::Alfred.delete(round_robin_key)
  end

  # called on call_settings member create
  def add_agent_to_queue(user_id)
    ::Redis::Alfred.lpush(round_robin_key, user_id)
  end

  # called on call_settings member delete
  def remove_agent_from_queue(user_id)
    ::Redis::Alfred.lrem(round_robin_key, user_id)
  end

  def reset_queue
    clear_queue
    add_agent_to_queue(account.users.map(&:id))
  end

  # end of queue management functions

  # allowed member ids = [assignable online agents supplied by the assignment service]
  # the values of allowed member ids should be in string format
  def available_agent(allowed_agent_ids: [])
    reset_queue unless validate_queue?

    user_id = get_member_from_allowed_agent_ids(allowed_agent_ids)
    account.agents.find_by(id: user_id) if user_id.present?
  end

  # returns an array of agents (sorted by round robin)
  def available_agents(allowed_agent_ids: [])
    Rails.logger.info "Allowed agent ids: #{allowed_agent_ids.inspect}"
    reset_queue unless validate_queue?
    Rails.logger.info "Queue: #{queue.inspect}"
    # return queue as array
    agent_ids = queue.intersection(allowed_agent_ids)
    Rails.logger.info "Agent ids: #{agent_ids.inspect}"
    Rails.logger.info "SQL: #{account.agents.where(id: agent_ids).to_sql}"
    account.users.where(id: agent_ids)
  end

  # called when an agent is picked
  def agent_picked(user_id)
    reset_queue unless validate_queue?

    pop_push_to_queue(user_id)
  end

  private

  def get_member_from_allowed_agent_ids(allowed_agent_ids)
    return nil if allowed_agent_ids.blank?

    Rails.logger.info "Queue: #{queue.inspect}"
    user_id = queue.intersection(allowed_agent_ids).pop
    Rails.logger.info "User id: #{user_id.inspect}"
    pop_push_to_queue(user_id)
    user_id
  end

  def pop_push_to_queue(user_id)
    return if user_id.blank?

    remove_agent_from_queue(user_id)
    add_agent_to_queue(user_id)
  end

  def validate_queue?
    # TODO: validate queue via agents added to call_settings
    return true if account.users.pluck(:id).sort == queue.map(&:to_i).sort
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS_CALLING, account_id: account.id)
  end
end
