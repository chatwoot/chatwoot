# frozen_string_literal: true

class AssignmentV2::AssignmentJob < ApplicationJob
  queue_as :low

  def perform(inbox_id: nil, conversation_id: nil)
    if conversation_id
      assign_single_conversation(conversation_id)
    elsif inbox_id
      assign_inbox_conversations(inbox_id)
    else
      Rails.logger.error 'AssignmentV2::AssignmentJob: No inbox_id or conversation_id provided'
    end
  end

  private

  def assign_single_conversation(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    service = AssignmentV2::AssignmentService.new(inbox: conversation.inbox)
    service.perform_for_conversation(conversation)
  end

  def assign_inbox_conversations(inbox_id)
    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox
    return unless inbox.assignment_v2_enabled?

    service = AssignmentV2::AssignmentService.new(inbox: inbox)
    assigned_count = service.perform_bulk_assignment

    Rails.logger.info "AssignmentV2::AssignmentJob: Assigned #{assigned_count} conversations for inbox #{inbox_id}"
  end
end
