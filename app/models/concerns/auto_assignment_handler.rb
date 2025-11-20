module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  EMPTY_QUEUE_THRESHOLD = 3.freeze

  included do
    after_create :run_auto_assignment
  end

  private

  def run_auto_assignment
    # Round robin kicks in on conversation create & update
    # run it only when conversation status changes to open
    return unless should_run_auto_assignment?

    if account.queue_enabled?
      handle_queue_assignment
    else
      return unless should_run_auto_assignment?
      handle_standard_assignment
    end
  end

  def find_available_agent_for(conversation)
    queue_service = ChatQueue::QueueService.new(account: account)

    queue_service.online_agents_list.each do |agent_id|
      agent = User.find_by(id: agent_id)
      next unless agent

      next unless queue_service.conversation_allowed_for_agent?(conversation, agent)
      next unless queue_service.agent_available?(agent)
  
      return agent
    end

    nil
  end

  def conversation_status_changed_to_resolved_or_snoozed?
    inbox.auto_assignment_v2_enabled? && saved_change_to_status? && (resolved? || snoozed?)
  end

  def team_member_ids_with_capacity
    return [] if team.blank? || team.allow_auto_assign.blank?

    inbox.member_ids_with_assignment_capacity & team.members.ids
  end

  def should_run_auto_assignment?
    if account.queue_enabled?
      return false if status == "queued"

      return true
    end
  
    return false unless inbox.enable_auto_assignment?
    # Assignment V2: Resolved/snoozed conversations still have an assignee, so bypass the
    # assignee-blank check below. The AssignmentJob needs to run to rebalance assignments.
    return true if conversation_status_changed_to_resolved_or_snoozed?

    if assignee.blank? || inbox.members.exclude?(assignee)
      return true
    end

    false
  end

  def handle_queue_assignment
    queue_service = ChatQueue::QueueService.new(account: account)

    if assignee_id.present?
      self.update_column(:assignee_id, nil)
    end

    if queue_service.queue_size.zero?
          assignee = find_available_agent_for(self)
      if assignee && assignee_id.nil?
        update!(assignee: assignee, status: :open)
      else
        queue_service.add_to_queue(self)
      end
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
