# frozen_string_literal: true

class AssignmentV2::RoundRobinSelector
  pattr_initialize [:inbox!]

  def select_agent(available_agents)
    return nil if available_agents.empty?

    # Extract user IDs from inbox members
    agent_user_ids = available_agents.map(&:user_id).map(&:to_s)

    # Use Redis queue for round robin
    selected_user_id = round_robin_service.available_agent(allowed_agent_ids: agent_user_ids)
    return nil unless selected_user_id

    # Return the user object
    available_agents.find { |inbox_member| inbox_member.user_id.to_s == selected_user_id }&.user
  end

  def add_agent_to_queue(user_id)
    round_robin_service.add_agent_to_queue(user_id)
  end

  def remove_agent_from_queue(user_id)
    round_robin_service.remove_agent_from_queue(user_id)
  end

  def reset_queue
    round_robin_service.reset_queue
  end

  private

  def round_robin_service
    @round_robin_service ||= AutoAssignment::InboxRoundRobinService.new(inbox: inbox)
  end
end
