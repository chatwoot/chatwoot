# frozen_string_literal: true

# Rate limiter for assignment operations
# Uses Redis to track assignment counts per agent per time window
# based on assignment policy's fair_distribution_limit and fair_distribution_window
class AssignmentV2::RateLimiter
  pattr_initialize [:inbox!, :user!]

  # Check if the user has exceeded rate limits
  # @return [Boolean] true if within limits, false if exceeded
  def within_limits?
    return true unless policy_exists?

    current_count < rate_limit
  end

  # Record an assignment for rate limiting purposes
  # @param conversation [Conversation] The conversation being assigned
  def record_assignment(conversation)
    return unless policy_exists?

    key = rate_limit_key
    $alfred.with do |redis|
      redis.multi do |multi|
        multi.incr(key)
        multi.expire(key, time_window)
      end
    end
  end

  # Get current rate limit status for the user
  # @return [Hash] Rate limit status information
  def status
    if policy_exists?
      {
        within_limits: within_limits?,
        current_count: current_count,
        limit: rate_limit,
        reset_at: Time.at(next_window_start)
      }
    else
      {
        within_limits: true,
        current_count: 0,
        limit: Float::INFINITY,
        reset_at: nil
      }
    end
  end

  private

  def policy
    @policy ||= inbox.assignment_policy
  end

  def policy_exists?
    policy.present? && policy.enabled?
  end

  def current_count
    key = rate_limit_key
    $alfred.with { |redis| redis.get(key).to_i }
  end

  def rate_limit
    policy&.fair_distribution_limit || 10
  end

  def time_window
    policy&.fair_distribution_window || 3600
  end

  def rate_limit_key
    "assignment_v2:rate_limit:#{user.id}:#{current_window}"
  end

  def current_window
    (Time.current.to_i / time_window) * time_window
  end

  def next_window_start
    current_window + time_window
  end
end