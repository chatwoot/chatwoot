class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    round_robin_manage_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  # Locks the row to serialize with concurrent assignment writers, then sets the assignee
  # on the in-memory conversation without saving. Called from the conversation's own
  # before_save so status and assignee commit as one change-set and both stay visible to
  # the after_commit callbacks. Returns the new assignee, or nil when nothing changed.
  def assign_under_lock
    locked = Conversation.lock.find_by(id: conversation.id)
    return unless locked && reassignment_still_needed?(locked)

    new_assignee = find_assignee
    return unless new_assignee

    conversation.assignee_id = locked.assignee_id
    conversation.clear_attribute_changes([:assignee_id])
    conversation.assignee = new_assignee
  end

  def perform
    # Standalone assignment with its own save (create path). Write through conversation
    # itself so its already-registered after_commit callbacks actually fire.
    Conversation.transaction do
      conversation.save if assign_under_lock
    end
  end

  private

  def reassignment_still_needed?(locked_conversation)
    return false if locked_conversation.assignee_agent_bot_id.present?

    locked_conversation.assignee.blank? || locked_conversation.inbox.members.exclude?(locked_conversation.assignee)
  end

  def online_agent_ids
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def allowed_online_agent_ids
    # We want to perform roundrobin only over online agents
    # Hence taking an intersection of online agents and allowed member ids

    # the online user ids are string, since its from redis, allowed member ids are integer, since its from active record
    @allowed_online_agent_ids ||= online_agent_ids & allowed_agent_ids&.map(&:to_s)
  end

  def round_robin_manage_service
    @round_robin_manage_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: conversation.inbox)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  end
end
