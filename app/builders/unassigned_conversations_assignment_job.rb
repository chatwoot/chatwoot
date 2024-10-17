class UnassignedConversationsAssignmentJob < ApplicationJob
  queue_as :critical

  def perform(inbox_id)
    cache_key = "unassigned_conversations_assignment_job_status_#{inbox_id}"

    cache_value = Rails.cache.read(cache_key)

    return if cache_value == 'running'

    Rails.cache.write(cache_key, 'running')

    inbox = Inbox.find(inbox_id)

    unassigned_conversations = inbox.conversations.unassigned

    unassigned_conversations.each do |conversation|
      ::AutoAssignment::AgentAssignmentService.new(conversation: conversation, allowed_agent_ids: inbox.member_ids_with_assignment_capacity).perform
    end

    Rails.cache.delete(cache_key)
  end
end
