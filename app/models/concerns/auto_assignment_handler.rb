module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_auto_assignment
  end

  private

  def run_auto_assignment
    # Assignment V2: Also trigger assignment when conversation is resolved or snoozed,
    # bypassing the open-only condition so the AssignmentJob can redistribute capacity.
    return unless conversation_status_changed_to_open? || conversation_status_changed_to_resolved_or_snoozed?
    return unless should_run_auto_assignment?

    if account.queue_enabled?
      handle_queue_assignment
    else
      handle_standard_assignment
    end
  end

  def find_available_agent_for(conversation)
    queue_service = ChatQueue::QueueService.new(account: account)

    queue_service.online_agents_list.each do |agent_id|
      agent = User.find_by(id: agent_id)
      next unless agent
      next unless queue_service.agent_available?(agent)
      next unless queue_service.conversation_allowed_for_agent?(conversation, agent)

      return agent
    end

    nil
  end

  def find_available_agent_for(conversation)
    queue_service = ChatQueue::QueueService.new(account: account)

    queue_service.online_agents_list.each do |agent_id|
      agent = User.find_by(id: agent_id)
      next unless agent
      next unless queue_service.agent_available?(agent)
      next unless queue_service.conversation_allowed_for_agent?(conversation, agent)

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
    return false unless inbox.enable_auto_assignment?
    # Assignment V2: Resolved/snoozed conversations still have an assignee, so bypass the
    # assignee-blank check below. The AssignmentJob needs to run to rebalance assignments.
    return true if conversation_status_changed_to_resolved_or_snoozed?

    # run only if assignee is blank or doesn't have access to inbox
    assignee.blank? || inbox.members.exclude?(assignee)
  end

  def handle_queue_assignment
    queue_service = ChatQueue::QueueService.new(account: account)

    assignee = find_available_agent_for(self)

    if queue_service.queue_size.positive?
      queue_service.add_to_queue(self)
      return
    end
    
    if assignee
      update!(assignee: assignee, status: :open)
      return
    end
    
    queue_service.add_to_queue(self)
  end

  def handle_standard_assignment
    assignee = ::AutoAssignment::AgentAssignmentService.new(
      conversation: self,
      allowed_agent_ids: inbox.member_ids_with_assignment_capacity
    ).find_assignee

    update!(assignee: assignee) if assignee
  end
end
