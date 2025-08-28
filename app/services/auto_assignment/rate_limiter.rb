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
    config['fair_distribution_limit']&.to_i
  end

  def window
    config['fair_distribution_window']&.to_i || 3600
  end

  def config
    @config ||= inbox.auto_assignment_config || {}
  end

  def assignment_key_pattern
    "assignment:#{inbox.id}:agent:#{agent.id}:*"
  end

  def build_assignment_key(conversation_id)
    "assignment:#{inbox.id}:agent:#{agent.id}:conversation:#{conversation_id}"
  end
end
