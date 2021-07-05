module RoundRobinHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_round_robin
  end

  private

  def run_round_robin
    # Round robin kicks in on conversation create & update
    # run it only when conversation status changes to open
    return unless conversation_status_changed_to_open?
    return unless should_round_robin?

    ::RoundRobin::AssignmentService.new(conversation: self).perform
  end

  def should_round_robin?
    return false unless inbox.enable_auto_assignment?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end
end
