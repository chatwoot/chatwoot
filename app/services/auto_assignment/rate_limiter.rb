class AutoAssignment::RateLimiter
  pattr_initialize [:inbox!, :agent!]

  def within_limit?
    current_count < limit
  end

  def track_assignment(conversation)
    Redis::Alfred.pipelined do |pipeline|
      pipeline.zremrangebyscore(assignment_key, '-inf', window_start)
      pipeline.zadd(assignment_key, Time.now.to_i, conversation.id)
      pipeline.expire(assignment_key, window)
    end
  end

  def current_count
    Redis::Alfred.zcount(assignment_key, "(#{window_start}", '+inf')
  end

  private

  def limit
    config&.fair_distribution_limit.present? ? config.fair_distribution_limit.to_i : 5
  end

  def window
    config&.fair_distribution_window&.to_i || 5.minutes.to_i
  end

  def window_start
    Time.now.to_i - window
  end

  def config
    @config ||= inbox.assignment_policy
  end

  def assignment_key
    format(Redis::RedisKeys::ASSIGNMENT_KEY, inbox_id: inbox.id, agent_id: agent.id)
  end
end
