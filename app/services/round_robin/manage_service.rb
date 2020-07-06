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

  def available_agent
    user_id = ::Redis::Alfred.rpoplpush(round_robin_key, round_robin_key)
    inbox.account.users.find_by(id: user_id)
  end

  private

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end
end
