# frozen_string_literal: true

module Enterprise
  class AssignmentV2::BalancedSelector
    pattr_initialize [:inbox!]

    def select_agent(available_agents)
      return nil if available_agents.empty?

      # Since agents are already filtered by capacity, we can compute workload distribution
      agents_with_workload = compute_agent_workloads(available_agents)
      return nil if agents_with_workload.empty?

      # Select agent with lowest current workload
      best_agent_data = agents_with_workload.min_by { |data| data[:current_assignments] }
      best_agent_data[:agent]
    rescue StandardError => e
      Rails.logger.error "AssignmentV2: Balanced selection failed: #{e.message}"
      # Fallback to simple selection
      available_agents.first&.user
    end

    private

    def compute_agent_workloads(available_agents)
      available_agents.map do |inbox_member|
        agent = inbox_member.user
        
        # Count current assignments
        current_assignments = agent.assigned_conversations
                                  .where(inbox: inbox)
                                  .open
                                  .count

        {
          agent: agent,
          current_assignments: current_assignments
        }
      end
    end
  end
end