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
    return if skip_due_to_queue_status_change?
    return unless conversation_status_changed_to_open?
    return unless should_run_auto_assignment?

    if account.queue_enabled?
      handle_queue_assignment
    else
      return unless should_run_auto_assignment?

      handle_standard_assignment
    end
  end

  def skip_due_to_queue_status_change?
    saved_change_to_status? && status == 'open' && status_before_last_save == 'queued'
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
    return true if assignee.blank? || inbox.members.exclude?(assignee)

    false
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

  def handle_standard_assignment
    assignee = ::AutoAssignment::AgentAssignmentService.new(
      conversation: self,
      allowed_agent_ids: inbox.member_ids_with_assignment_capacity
    ).find_assignee

    update!(assignee: assignee) if assignee
  end
end
