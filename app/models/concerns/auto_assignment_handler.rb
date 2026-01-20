module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_auto_assignment
  end

  def run_auto_assignment_for_web_widget_inbox
    return if stop_auto_assignment_for_web_widget

    Rails.logger.info("member_ids_with_assignment_capacity, #{inbox.member_ids_with_assignment_capacity}")

    ::AutoAssignment::AgentAssignmentService.new(
      conversation: self,
      allowed_agent_ids: inbox.member_ids_with_assignment_capacity,
      send_customer_message: true
    ).perform
  end

  private

  def run_auto_assignment
    # Round robin kicks in on conversation create & update
    # run it only when conversation status changes to open
    return unless conversation_status_changed_to_open?
    return unless should_run_auto_assignment?

    ::AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: inbox.member_ids_with_assignment_capacity).perform
  end

  def stop_auto_assignment_for_web_widget
    Rails.logger.info('AutoAssignment not running')
    Rails.logger.info("AutoAssignmentEmailData, #{assignee&.email&.match?(/\Acx\..+@bitespeed\.co\z/)}")
    return true if inbox.channel_type == 'Channel::WebWidget' && assignee&.email&.match?(/\Acx\..+@bitespeed\.co\z/)

    false
  end

  def should_run_auto_assignment?
    return false unless inbox.enable_auto_assignment?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end
end
