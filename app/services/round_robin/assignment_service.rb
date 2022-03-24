class RoundRobin::AssignmentService
  pattr_initialize [:conversation, { allowed_member_ids: [] }]

  def find_assignee
    round_robin_manage_service.available_agent(priority_list: online_agents)
  end

  def perform
    # online agents will get priority
    new_assignee = find_assignee
    conversation.update(assignee: new_assignee) if new_assignee
  end

  private

  def online_agents
    online_agents = OnlineStatusTracker.get_available_users(conversation.account_id)
    online_agents.select { |_key, value| value.eql?('online') }.keys if online_agents.present?
  end

  def round_robin_manage_service
    @round_robin_manage_service ||= RoundRobin::ManageService.new(inbox: conversation.inbox, allowed_member_ids: allowed_member_ids)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  end
end
