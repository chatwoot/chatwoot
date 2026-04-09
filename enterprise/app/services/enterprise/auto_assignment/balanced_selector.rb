class Enterprise::AutoAssignment::BalancedSelector
  pattr_initialize [:inbox!]

  def select_agent(available_agents)
    return nil if available_agents.empty?

    agent_users = available_agents.map(&:user)
    assignment_counts = fetch_assignment_counts(agent_users)

    agent_users.min_by { |user| assignment_counts[user.id] || 0 }
  end

  private

  def fetch_assignment_counts(users)
    user_ids = users.map(&:id)

    counts = inbox.conversations
                  .open
                  .where(assignee_id: user_ids)
                  .group(:assignee_id)
                  .count

    Hash.new(0).merge(counts)
  end
end
