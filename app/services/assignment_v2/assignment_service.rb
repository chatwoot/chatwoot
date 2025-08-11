# frozen_string_literal: true

class AssignmentV2::AssignmentService
  pattr_initialize [:inbox!]

  def perform_for_conversation(conversation)
    return false unless can_assign?(conversation)

    agent = find_agent_for_conversation(conversation)
    return false unless agent

    assign_conversation_to_agent(conversation, agent)
  end

  def perform_bulk_assignment(limit: 50)
    return 0 unless assignment_enabled?

    conversations = unassigned_conversations(limit)
    assigned_count = 0

    conversations.find_each do |conversation|
      assigned_count += 1 if perform_for_conversation(conversation)
    end

    assigned_count
  end

  private

  def policy
    @policy ||= inbox.assignment_policy
  end

  def assignment_enabled?
    policy&.enabled?
  end

  def can_assign?(conversation)
    assignment_enabled? &&
      conversation.status == 'open' &&
      conversation.assignee_id.nil?
  end

  def find_agent_for_conversation(_conversation)
    available_agents = inbox.available_agents(check_rate_limits: true)

    if available_agents.empty?
      log_no_agents_available
      return nil
    end

    selector_service.select_agent(available_agents)
  end

  def selector_service
    @selector_service ||= AssignmentV2::RoundRobinSelector.new(inbox: inbox)
  end

  def unassigned_conversations(limit)
    scope = inbox.conversations
                 .unassigned
                 .open

    # Apply conversation priority ordering
    scope = case policy.conversation_priority
            when 'longest_waiting'
              scope.order(last_activity_at: :asc, created_at: :asc)
            else
              scope.order(created_at: :asc)
            end

    scope.limit(limit)
  end

  def assign_conversation_to_agent(conversation, agent)
    conversation.update!(assignee: agent)
    create_assignment_activity(conversation, agent)
    record_assignment_in_rate_limiter(conversation, agent)
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "AssignmentV2: Failed to assign conversation #{conversation.id}: #{e.message}"
    false
  end

  def create_assignment_activity(conversation, agent)
    Rails.configuration.dispatcher.dispatch(
      Events::Types::ASSIGNEE_CHANGED,
      Time.zone.now,
      conversation: conversation,
      user: agent
    )
  end

  def enterprise_enabled?
    @enterprise_enabled ||= defined?(Enterprise)
  end

  def log_no_agents_available
    Rails.logger.warn("AssignmentV2: No agents available for inbox #{inbox.id}")
  end

  def record_assignment_in_rate_limiter(conversation, agent)
    rate_limiter = AssignmentV2::RateLimiter.new(inbox: inbox, user: agent)
    rate_limiter.record_assignment(conversation)
  rescue StandardError => e
    Rails.logger.error "AssignmentV2: Failed to record assignment in rate limiter: #{e.message}"
  end
end

AssignmentV2::AssignmentService.prepend_mod_with('AssignmentV2::AssignmentService')
