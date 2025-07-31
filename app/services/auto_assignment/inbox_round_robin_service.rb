class AutoAssignment::InboxRoundRobinService
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

  def reset_queue
    clear_queue
    inbox.inbox_members.each do |member|
      add_agent_to_queue(member.user_id)
    end
  end

  # end of queue management functions

  # allowed member ids = [assignable online agents supplied by the assignment service]
  # the values of allowed member ids should be in string format
  def available_agent(allowed_agent_ids: [])
    reset_queue unless validate_queue?
    get_member_from_allowed_agent_ids(allowed_agent_ids)
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
    inbox.inbox_members.map(&:user_id).map(&:to_s).sort == queue.sort
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end
end
