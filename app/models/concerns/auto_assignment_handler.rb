module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    before_save :run_legacy_auto_assignment, unless: :new_record?
    after_save :run_auto_assignment
  end

  private

  # Legacy (V1) assignment for status changes runs inside the same save, so status and
  # assignee commit as one change-set; a follow-up save would reset saved_changes and
  # hide the status change from the after_commit callbacks (no conversation.opened).
  def run_legacy_auto_assignment
    return if skip_due_to_queue_status_change?
    return if account.queue_enabled?
    return unless status_changed? && open?
    return if inbox.auto_assignment_v2_enabled?
    return unless should_run_auto_assignment?

    AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: legacy_allowed_agent_ids).assign_under_lock
  end

  def run_auto_assignment
    return if skip_due_to_queue_status_change?

    if account.queue_enabled?
      return unless conversation_status_changed_to_open?
      return unless should_run_auto_assignment?

      handle_queue_assignment
      return
    end

    # Assignment V2: Also trigger assignment when conversation is resolved or snoozed,
    # bypassing the open-only condition so the AssignmentJob can redistribute capacity.
    return unless conversation_status_changed_to_open? || conversation_status_changed_to_resolved_or_snoozed?
    return unless should_run_auto_assignment?

    if inbox.auto_assignment_v2_enabled?
      # Coalesces bursts of triggers per inbox. Fine if the job runs even when the
      # surrounding save rolls back: it only scans the inbox's current unassigned
      # conversations, so running it for an uncommitted change is harmless.
      AutoAssignment::AssignmentJob.enqueue_for_inbox(inbox.id)
    elsif saved_change_to_id?
      # Legacy (V1) assignment for new conversations stays post-save: their status is only
      # finalized by before_create callbacks, which run after before_save.
      AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: legacy_allowed_agent_ids).perform
    end
  end

  def skip_due_to_queue_status_change?
    saved_change_to_status? && status == 'open' && status_before_last_save == 'queued'
  end

  def legacy_allowed_agent_ids
    # If conversation has a team, only consider team members for assignment
    team_id.present? ? team_member_ids_with_capacity : inbox.member_ids_with_assignment_capacity
  end

  def conversation_status_changed_to_resolved_or_snoozed?
    inbox.auto_assignment_v2_enabled? && saved_change_to_status? && (resolved? || snoozed?)
  end

  def team_member_ids_with_capacity
    return [] if team.blank? || team.allow_auto_assign.blank?

    inbox.member_ids_with_assignment_capacity & team.members.ids
  end

  def find_available_agent_for(conversation)
    selector = ChatQueue::Agents::SelectorService.new(account: account)
    permissions = ChatQueue::Agents::PermissionsService.new(account: account)
    availability = ChatQueue::Agents::AvailabilityService.new(account: account)

    selector.online_agents.each do |agent|
      next unless permissions.allowed?(conversation, agent)
      next unless availability.available?(agent)

      return agent
    end

    nil
  end

  def should_run_auto_assignment?
    if account.queue_enabled?
      return false if status == 'queued'

      return true
    end

    return false unless inbox.enable_auto_assignment?
    # Assignment V2: Resolved/snoozed conversations still have an assignee, so bypass the
    # assignee-blank check below. The AssignmentJob needs to run to rebalance assignments.
    return true if conversation_status_changed_to_resolved_or_snoozed?
    return false if assignee_agent_bot_id.present?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end

  def handle_queue_assignment
    queue_service = ChatQueue::QueueService.new(account: account)

    return if queued_or_assigned?

    clear_assignee_if_present

    if queue_empty?(queue_service)
      handle_direct_or_queued_assignment(queue_service)
    else
      queue_service.add_to_queue(self)
    end
  end

  def queued_or_assigned?
    queued? || assignee.present?
  end

  # rubocop:disable Rails/SkipsModelValidations
  def clear_assignee_if_present
    update_columns(assignee_id: nil) if assignee_id.present?
  end
  # rubocop:enable Rails/SkipsModelValidations

  def queue_empty?(_queue_service)
    fetcher = ChatQueue::Queue::FetchService.new(account: account)
    fetcher.queue_size(inbox_id).zero?
  end

  def handle_direct_or_queued_assignment(queue_service)
    assignee = find_available_agent_for(self)

    if assignee && assignee_id.nil?
      update!(assignee: assignee, status: :open)
    else
      queue_service.add_to_queue(self)
    end
  end
end
