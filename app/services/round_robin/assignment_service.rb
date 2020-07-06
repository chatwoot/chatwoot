class RoundRobin::AssignmentService
  pattr_initialize [:conversation]

  def perform
    new_assignee = RoundRobin::ManageService.new(conversation.inbox).available_agent
    conversation.update(assignee: new_assignee) if new_assignee
  end

  private

  def round_robin_manage_service
    @round_robin_manage_service ||= RoundRobin::ManageService.new(conversation.inbox)
  end

  def round_robin_key
    format(::Redis::Alfred::ROUND_ROBIN_AGENTS, inbox_id: conversation.inbox_id)
  end
end
