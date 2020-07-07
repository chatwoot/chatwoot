class RoundRobin::ManageService
  pattr_initialize [:inbox!]

  # called on inbox delete
  def clear_queue
    ::Redis::Alfred.delete(round_robin_key)
  end

  # called on inbox member create
  def add_agent_to_queue(user_id)
    ::Redis::Alfred.lpush(round_robin_key, user_id)
  end

  # called on inbox member delete
  def remove_agent_from_queue(user_id)
    ::Redis::Alfred.lrem(round_robin_key, user_id)
  end

  def available_agent(priority_list: [])
    reset_queue unless validate_queue?
    user_id = get_agent_via_priority_list(priority_list)
    # incase priority list was empty or inbox members weren't present
    user_id ||= ::Redis::Alfred.rpoplpush(round_robin_key, round_robin_key)
    inbox.inbox_members.find_by(user_id: user_id)&.user if user_id.present?
  end

  def reset_queue
    clear_queue
    add_agent_to_queue(inbox.inbox_members.map(&:user_id))
  end

  private

  def get_agent_via_priority_list(priority_list)
    return if priority_list.blank?

    user_id = queue.intersection(priority_list.map(&:to_s)).pop
    if user_id.present?
      remove_agent_from_queue(user_id)
      add_agent_to_queue(user_id)
    end
    user_id
  end

  def validate_queue?
    return true if inbox.inbox_members.map(&:user_id).sort == queue.sort.map(&:to_i)
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end
end
