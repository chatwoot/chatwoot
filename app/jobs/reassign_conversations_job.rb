# frozen_string_literal: true

class ReassignConversationsJob < ApplicationJob
  queue_as :low

  def perform(account_user)
    return unless account_user

    user = account_user.user
    account = account_user.account

    # Find all open conversations assigned to this user
    conversations = account.conversations
                           .open
                           .where(assignee: user)

    Rails.logger.info "Reassigning #{conversations.count} conversations for user #{user.name} (#{user.id}) on leave"

    conversations.find_each do |conversation|
      reassign_conversation(conversation)
    end
  end

  private

  def reassign_conversation(conversation)
    inbox = conversation.inbox

    # Use Assignment V2 if enabled
    if inbox.assignment_v2_enabled?
      assignment_service = AssignmentV2::AssignmentService.new(inbox: inbox)

      # Mark conversation as unassigned first
      conversation.update!(assignee: nil)

      # Let the assignment service handle it
      assignment_service.perform_for_conversation(conversation)
    else
      # Fallback to auto assignment
      AutoAssignmentService.new(
        conversation: conversation,
        allowed_agent_ids: inbox.assignable_agents.map(&:id) - [conversation.assignee_id]
      ).perform
    end
  rescue StandardError => e
    Rails.logger.error "Failed to reassign conversation #{conversation.id}: #{e.message}"
  end
end
