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

  def should_run_auto_assignment?
    return false unless inbox.enable_auto_assignment?

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
