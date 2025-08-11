# frozen_string_literal: true

class Enterprise::AssignmentV2::BalancedSelector
  pattr_initialize [:inbox!]

  def select_agent(available_agents)
    return nil if available_agents.empty?

    # Get current assignment counts for all available agents
    agent_users = available_agents.map(&:user)
    assignment_counts = fetch_assignment_counts(agent_users)

    # Find the agent with the least assignments
    selected_agent = agent_users.min_by { |user| assignment_counts[user.id] || 0 }

    # Log the selection for debugging
    Rails.logger.info "BalancedSelector: Selected agent #{selected_agent.id} with #{assignment_counts[selected_agent.id] || 0} assignments"

    selected_agent
  end

  def add_agent_to_queue(user_id)
    # No-op for balanced assignment - we don't maintain a queue
  end

  def remove_agent_from_queue(user_id)
    # No-op for balanced assignment - we don't maintain a queue
  end

  def reset_queue
    # No-op for balanced assignment - we don't maintain a queue
  end

  private

  def fetch_assignment_counts(users)
    # Get open conversation counts for each user
    user_ids = users.map(&:id)

    # Count open conversations assigned to each user in this inbox
    counts = inbox.conversations
                  .open
                  .where(assignee_id: user_ids)
                  .group(:assignee_id)
                  .count

    # Convert to hash with default value of 0
    Hash.new(0).merge(counts)
  end

  def account
    @account ||= inbox.account
  end
end
