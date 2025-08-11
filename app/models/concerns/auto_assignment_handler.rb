module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_auto_assignment
  end

  private

  def run_auto_assignment
    # Round robin kicks in on conversation create & update
    # run it only when conversation status changes to open
    return unless conversation_status_changed_to_open?
    return unless should_run_auto_assignment?

    if inbox.assignment_v2_enabled?
      # Use Assignment V2 system
      AssignmentV2::AssignmentJob.perform_later(conversation_id: id)
    else
      # Use legacy assignment system
      ::AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: inbox.member_ids_with_assignment_capacity).perform
    end
  end

  def should_run_auto_assignment?
    # Check auto assignment is enabled (either legacy or v2)
    return false unless inbox.auto_assignment_enabled?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end
end
