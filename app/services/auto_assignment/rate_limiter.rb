class AutoAssignment::RateLimiter
  pattr_initialize [:inbox!, :agent!]

  def within_limit?
    return true unless enabled?

    current_count < limit
  end

  def track_assignment(conversation)
    return unless enabled?

    assignment_key = build_assignment_key(conversation.id)
    Redis::Alfred.set(assignment_key, conversation.id.to_s, ex: window)
  end

  def current_count
    return 0 unless enabled?

    pattern = assignment_key_pattern
    Redis::Alfred.keys_count(pattern)
  end

  private

  def enabled?
    limit.present? && limit.positive?
  end

  def limit
    config&.fair_distribution_limit&.to_i || Math
  end

  def window
    config&.fair_distribution_window&.to_i || 24.hours.to_i
  end

  def config
    @config ||= inbox.assignment_policy
  end

  def assignment_key_pattern
    format(Redis::RedisKeys::ASSIGNMENT_KEY_PATTERN, inbox_id: inbox.id, agent_id: agent.id)
  end

  def build_assignment_key(conversation_id)
    format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id, conversation_id: conversation_id)
  end
end
