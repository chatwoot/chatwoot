class AutoAssignment::AgentAssignmentService
  # Allowed agent ids: array
  # This is the list of agents from which an agent can be assigned to this conversation
  # examples: Agents with assignment capacity, Agents who are members of a team etc
  pattr_initialize [:conversation!, :allowed_agent_ids!]

  def find_assignee
    round_robin_manage_service.available_agent(allowed_agent_ids: allowed_online_agent_ids)
  end

  def perform
    # This runs from Conversation's own after_save callback (AutoAssignmentHandler), so
    # conversation is often still mid-way through its own save. Locking a fresh, separate
    # instance (rather than conversation.with_lock, which would reload conversation itself)
    # avoids wiping previous_changes that later after_commit callbacks on it still depend on.
    Conversation.transaction do
      locked = Conversation.lock.find_by(id: conversation.id)
      next unless locked && reassignment_still_needed?(locked)

      new_assignee = find_assignee
      locked.update(assignee: new_assignee) if new_assignee
    end
  end

  private

  def reassignment_still_needed?(locked_conversation)
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
