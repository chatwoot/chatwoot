class AutoAssignment::CapacityService
  def agent_has_capacity?(user, inbox)
    account_user = user.account_users.find_by(account: inbox.account)

    # Agents without a capacity policy have unlimited capacity.
    return true unless account_user&.agent_capacity_policy

    policy = account_user.agent_capacity_policy
    inbox_limit = policy.inbox_capacity_limits.find_by(inbox: inbox)

    # Without an inbox-specific limit, the agent has unlimited capacity here.
    return true unless inbox_limit

    current_count = user.assigned_conversations
                        .where(inbox: inbox, status: :open)
                        .count

    current_count < inbox_limit.conversation_limit
  end

  # Batch version: returns subset of users that have capacity for inbox.
  # Avoids N+1 by preloading account_users, policies, limits and conversation counts in bulk.
  def filter_agents_with_capacity(users, inbox)
    return users if users.empty?

    # Preload counts per user for this inbox in one query
    open_counts = Conversation.where(inbox: inbox, status: :open, assignee_id: users.map(&:id))
                              .group(:assignee_id).count

    # Preload account_users with policies and limits
    account_users_by_user_id = AccountUser.where(account: inbox.account, user_id: users.map(&:id))
                                          .includes(agent_capacity_policy: :inbox_capacity_limits)
                                          .index_by(&:user_id)

    users.select do |user|
      account_user = account_users_by_user_id[user.id]
      # No policy -> unlimited
      next true unless account_user&.agent_capacity_policy

      inbox_limit = account_user.agent_capacity_policy.inbox_capacity_limits.find { |l| l.inbox_id == inbox.id }
      next true unless inbox_limit

      (open_counts[user.id] || 0) < inbox_limit.conversation_limit
    end
  end
end
