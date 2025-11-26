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
    Rails.logger.info("[AUTO_ASSIGN] Triggered for conversation #{id} | status=#{status} | assignee_id=#{assignee_id}")

    return Rails.logger.info("[AUTO_ASSIGN] Skip: conversation status didn't change to open for conversation #{id}") unless conversation_status_changed_to_open?
    return Rails.logger.info("[AUTO_ASSIGN] Skip: should_run_auto_assignment? returned false  for conversation #{id}") unless should_run_auto_assignment?

    if account.queue_enabled?
      Rails.logger.info("[AUTO_ASSIGN] Queue mode enabled running queue assignment for conversation #{id}")
      handle_queue_assignment
    else
      return unless should_run_auto_assignment?
      handle_standard_assignment
    end
  end

  def find_available_agent_for(conversation)
    queue_service = ChatQueue::QueueService.new(account: account)

    Rails.logger.info("[AUTO_ASSIGN] Searching available agent for conversation #{conversation.id}")
    Rails.logger.info("[AUTO_ASSIGN] Online agents: #{queue_service.online_agents_list.inspect} for conversation #{conversation.id}")

    queue_service.online_agents_list.each do |agent_id|
      agent = User.find_by(id: agent_id)
      
      Rails.logger.info("[AUTO_ASSIGN] Checking agent #{agent_id} exists? #{agent.present?} for conversation #{conversation.id}")
      next unless agent

      allowed = queue_service.conversation_allowed_for_agent?(conversation, agent)
      available = queue_service.agent_available?(agent)

      Rails.logger.info("[AUTO_ASSIGN] Agent #{agent.id}: allowed=#{allowed}, available=#{available} for conversation #{conversation.id}")

      next unless allowed
      next unless available
  
      Rails.logger.info("[AUTO_ASSIGN] Agent #{agent.id} selected for assignment for conversation #{conversation.id}")
      return agent
    end

    Rails.logger.info("[AUTO_ASSIGN] No available agent found for conversation #{conversation.id}")
    nil
  end

  def should_run_auto_assignment?
    Rails.logger.info("[AUTO_ASSIGN] Should run auto-assignment? conversation #{id}, status=#{status}, assignee_id=#{assignee_id}")

    if account.queue_enabled?
      Rails.logger.info("[AUTO_ASSIGN] Queue mode active for account #{account.id}")
      
      if status == "queued"
        Rails.logger.info("[AUTO_ASSIGN] Should NOT run: conversation is already queued  for conversation #{id}")
        return false
      end

      Rails.logger.info("[AUTO_ASSIGN] Should run in queue mode for conversation #{id}")
      return true
    end
  
    return false unless inbox.enable_auto_assignment?

    if assignee.blank? || inbox.members.exclude?(assignee)
      return true
    end

    Rails.logger.info("[AUTO_ASSIGN] Should NOT run: assignee is already a valid inbox member for conversation #{id}")
    false
  end

  def handle_queue_assignment
    queue_service = ChatQueue::QueueService.new(account: account)
  
    Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] handle_queue_assignment: queued?=#{queued?}, assignee_id=#{assignee_id}")
  
    return Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] Skip: conversation already queued or assigned") if queued? || assignee.present?
  
    if assignee_id.present?
      Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] Resetting assignee_id before queue assignment")
      update_column(:assignee_id, nil)
    end
  
    if queue_service.queue_size.zero?
      Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] Queue empty trying to assign immediately")
  
      assignee = find_available_agent_for(self)
  
      if assignee && assignee_id.nil?
        Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] Assigned immediately to agent #{assignee.id}")
        update_columns(assignee_id: assignee.id)
      else
        Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] No agent available pushing to queue")
        queue_service.add_to_queue(self)
      end
    else
      Rails.logger.info("[AUTO_ASSIGN][conversation=#{id}] Queue not empty (size=#{queue_service.queue_size}) adding to queue")
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
