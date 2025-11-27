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
    if saved_change_to_status? && status == "open" && status_before_last_save == "queued"
      return
    end
  
    return unless conversation_status_changed_to_open?
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

  def should_run_auto_assignment?
    if account.queue_enabled?
      return false if status == "queued"

      return true
    end
  
    return false unless inbox.enable_auto_assignment?

    if assignee.blank? || inbox.members.exclude?(assignee)
      return true
    end

    false
  end

  def handle_queue_assignment
    queue_service = ChatQueue::QueueService.new(account: account)
  
    return if queued? || assignee.present? 
  
    update_column(:assignee_id, nil) if assignee_id.present?
  
    if queue_service.queue_size(inbox_id).zero?
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
