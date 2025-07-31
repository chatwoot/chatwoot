# frozen_string_literal: true

class Enterprise::AssignmentV2::CapacityService
  pattr_initialize [:inbox!]

  def filter_agents_by_capacity(inbox_members)
    inbox_members.select do |inbox_member|
      agent = inbox_member.user
      available_capacity?(agent)
    end
  end

  def get_agent_capacity(agent)
    inbox_limit = get_inbox_limit_for_agent(agent)
    return unlimited_capacity unless inbox_limit

    current_count = count_current_assignments(agent)
    build_capacity_data(inbox_limit, current_count)
  end

  private

  def get_inbox_limit_for_agent(agent)
    account_user = agent.account_users.find_by(account: inbox.account)
    policy = account_user&.agent_capacity_policy
    return nil unless policy

    policy.inbox_capacity_limits.find_by(inbox: inbox)
  end

  def count_current_assignments(agent)
    agent.assigned_conversations
         .where(inbox: inbox)
         .open
         .count
  end

  def build_capacity_data(inbox_limit, current_count)
    {
      total_capacity: inbox_limit.conversation_limit,
      current_assignments: current_count,
      available_capacity: inbox_limit.conversation_limit - current_count
    }
  end

  def unlimited_capacity
    {
      total_capacity: Float::INFINITY,
      current_assignments: 0,
      available_capacity: Float::INFINITY
    }
  end

  def available_capacity?(agent)
    capacity_data = get_agent_capacity(agent)
    capacity_data[:available_capacity].positive?
  end
end
