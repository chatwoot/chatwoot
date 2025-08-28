class AutoAssignment::AssignmentService
  pattr_initialize [:inbox!]

  def perform_for_conversation(conversation)
    return false unless assignable?(conversation)

    agent = find_available_agent
    return false unless agent

    assign_conversation(conversation, agent)
  end

  def perform_bulk_assignment(limit: 100)
    return 0 unless inbox.enable_auto_assignment?

    assigned_count = 0

    unassigned_conversations(limit).find_each do |conversation|
      assigned_count += 1 if perform_for_conversation(conversation)
    end

    assigned_count
  end

  private

  def assignable?(conversation)
    inbox.enable_auto_assignment? &&
      conversation.status == 'open' &&
      conversation.assignee_id.nil?
  end

  def unassigned_conversations(limit)
    scope = inbox.conversations.unassigned.open

    # Apply conversation priority from config
    scope = apply_conversation_priority(scope)
    scope.limit(limit)
  end

  def apply_conversation_priority(scope)
    case assignment_config['conversation_priority']
    when 'longest_waiting'
      scope.order(last_activity_at: :asc, created_at: :asc)
    else
      scope.order(created_at: :asc)
    end
  end

  def find_available_agent
    agents = filter_agents_by_rate_limit(inbox.available_agents)
    return nil if agents.empty?

    round_robin_selector.select_agent(agents)
  end

  def filter_agents_by_rate_limit(agents)
    agents.select do |agent_member|
      rate_limiter = build_rate_limiter(agent_member.user)
      rate_limiter.within_limit?
    end
  end

  def assign_conversation(conversation, agent)
    conversation.update!(assignee: agent)

    rate_limiter = build_rate_limiter(agent)
    rate_limiter.track_assignment(conversation)

    dispatch_assignment_event(conversation, agent)
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "AutoAssignment failed for conversation #{conversation.id}: #{e.message}"
    false
  end

  def dispatch_assignment_event(conversation, agent)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::ASSIGNEE_CHANGED,
      Time.zone.now,
      conversation: conversation,
      user: agent
    )
  end

  def build_rate_limiter(agent)
    AutoAssignment::RateLimiter.new(inbox: inbox, agent: agent)
  end

  def round_robin_selector
    @round_robin_selector ||= AutoAssignment::RoundRobinSelector.new(inbox: inbox)
  end

  def assignment_config
    @assignment_config ||= inbox.auto_assignment_config || {}
  end
end

AutoAssignment::AssignmentService.prepend_mod_with('AutoAssignment::AssignmentService')
