class UnassignedConversationsAssignmentJob < ApplicationJob
  queue_as :critical

  def perform(inbox_id, suppress_no_agent_message: false) # rubocop:disable Metrics/MethodLength
    cache_key = "unassigned_conversations_assignment_job_status_#{inbox_id}"

    cache_value = Rails.cache.read(cache_key)

    return if cache_value == 'running'

    Rails.cache.write(cache_key, 'running')

    inbox = Inbox.find(inbox_id)

    unassigned_conversations = inbox.conversations.unassigned.order(created_at: :asc)
    unassigned_conversations = unassigned_conversations.open if suppress_no_agent_message

    unassigned_conversations.each do |conversation|
      allowed_agent_ids = inbox.member_ids_with_assignment_capacity

      if conversation.team_id?
        team_id = conversation.team_id
        team = Team.find_by(id: team_id)
        allowed_agent_ids &= team.members.ids if team.present?
      end

      ::AutoAssignment::AgentAssignmentService.new(
        conversation: conversation,
        allowed_agent_ids: allowed_agent_ids,
        suppress_no_agent_message: suppress_no_agent_message
      ).perform
    end

    Rails.cache.delete(cache_key)
  end
end
