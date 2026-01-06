class Enterprise::AutoAssignment::CapacityService
  def agent_has_capacity?(user, inbox)
    # Get the account_user for this specific account
    account_user = user.account_users.find_by(account: inbox.account)

    # If no account_user or no capacity policy, agent has unlimited capacity
    return true unless account_user&.agent_capacity_policy

    policy = account_user.agent_capacity_policy

    # Check if there's a specific limit for this inbox
    inbox_limit = policy.inbox_capacity_limits.find_by(inbox: inbox)

    # If no specific limit for this inbox, agent has unlimited capacity for this inbox
    return true unless inbox_limit

    # Count current open conversations for this agent in this inbox
    current_count = user.assigned_conversations
                        .where(inbox: inbox, status: :open)
                        .count

    # Agent has capacity if current count is below the limit
    current_count < inbox_limit.conversation_limit
  end
end
