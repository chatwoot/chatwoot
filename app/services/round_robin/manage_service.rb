# If allowed_member_ids are supplied round robin service will only fetch a member from member id
# This is used in case of team assignment
class RoundRobin::ManageService
  pattr_initialize [:inbox!, { allowed_member_ids: [] }]

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
    user_id = get_member_via_priority_list(priority_list)
    # incase priority list was empty or inbox members weren't present
    user_id ||= fetch_user_id
    inbox.inbox_members.find_by(user_id: user_id)&.user if user_id.present?
  end

  def reset_queue
    clear_queue
    add_agent_to_queue(inbox.inbox_members.map(&:user_id))
  end

  private

  def fetch_user_id
    if allowed_member_ids_in_str.present?
      user_id = queue.intersection(allowed_member_ids_in_str).pop
      pop_push_to_queue(user_id)
      user_id
    else
      ::Redis::Alfred.rpoplpush(round_robin_key, round_robin_key)
    end
  end

  # priority list is usually the members who are online passed from assignmebt service
  def get_member_via_priority_list(priority_list)
    return if priority_list.blank?

    # when allowed member ids is passed we will be looking to get members from that list alone
    priority_list = priority_list.intersection(allowed_member_ids_in_str) if allowed_member_ids_in_str.present?
    return if priority_list.blank?

    user_id = queue.intersection(priority_list.map(&:to_s)).pop
    pop_push_to_queue(user_id)
    user_id
  end

  def pop_push_to_queue(user_id)
    return if user_id.blank?

    remove_agent_from_queue(user_id)
    add_agent_to_queue(user_id)
  end

  def validate_queue?
    return true if inbox.inbox_members.map(&:user_id).sort == queue.map(&:to_i).sort
  end

  def queue
    ::Redis::Alfred.lrange(round_robin_key)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: inbox.id)
  end

  def allowed_member_ids_in_str
    # NOTE: the values which are returned from redis for priority list are string
    @allowed_member_ids_in_str ||= allowed_member_ids.map(&:to_s)
  end
end
