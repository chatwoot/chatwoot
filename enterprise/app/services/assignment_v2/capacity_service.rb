# frozen_string_literal: true

module Enterprise
  class AssignmentV2::CapacityService
    pattr_initialize [:inbox!]

    def filter_agents_by_capacity(inbox_members)
      inbox_members.select do |inbox_member|
        agent = inbox_member.user
        has_available_capacity?(agent)
      end
    end

    def get_agent_capacity(agent)
      account_user = agent.account_users.find_by(account: inbox.account)
      policy = account_user&.agent_capacity_policy

      unless policy
        return {
          total_capacity: Float::INFINITY,
          current_assignments: 0,
          available_capacity: Float::INFINITY
        }
      end

      inbox_limit = policy.inbox_capacity_limits.find_by(inbox: inbox)
      
      unless inbox_limit
        return {
          total_capacity: Float::INFINITY,
          current_assignments: 0,
          available_capacity: Float::INFINITY
        }
      end

      current_count = agent.assigned_conversations
                           .where(inbox: inbox)
                           .open
                           .count

      {
        total_capacity: inbox_limit.conversation_limit,
        current_assignments: current_count,
        available_capacity: inbox_limit.conversation_limit - current_count
      }
    end

    private

    def has_available_capacity?(agent)
      capacity_data = get_agent_capacity(agent)
      capacity_data[:available_capacity].positive?
    end
  end
end