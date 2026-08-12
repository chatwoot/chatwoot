class Captain::Routines::Operations::Queries::AgentGetWorkload < Captain::Routines::Operations::Query
  returns :one

  configure(
    name: 'agents.get_workload', effect: 'read',
    description: 'Load current assignment and capacity information for an agent.',
    arguments: { agent: 'agent name, email, ID, or reference' }, required: %w[agent]
  )

  def execute(agent:)
    user = agent!(agent)
    conversations = account.conversations.where(assignee: user, status: :open)
    account_user = account.account_users.find_by!(user: user)

    {
      'agent' => agent_data(user),
      'open_conversations' => conversations.count,
      'by_priority' => conversations.group(:priority).count.transform_keys { |priority| Conversation.priorities.key(priority) },
      'by_inbox' => conversations.group(:inbox_id).count.map do |inbox_id, count|
        { 'inbox' => inbox_data(account.inboxes.find(inbox_id)), 'open_conversations' => count }
      end,
      'capacity_policy' => capacity_policy_data(account_user)
    }
  end

  private

  def capacity_policy_data(account_user)
    policy = account_user.try(:agent_capacity_policy)
    return unless policy

    {
      'id' => policy.id,
      'name' => policy.name,
      'inbox_limits' => policy.inbox_capacity_limits.includes(:inbox).map do |limit|
        { 'inbox' => inbox_data(limit.inbox), 'conversation_limit' => limit.conversation_limit }
      end
    }
  end
end
