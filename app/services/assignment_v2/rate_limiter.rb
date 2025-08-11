# frozen_string_literal: true

# Rate limiter for assignment operations
# Uses SQL to track assignment counts per agent per time window
# based on assignment policy's fair_distribution_limit and fair_distribution_window
class AssignmentV2::RateLimiter
  pattr_initialize [:inbox!, :user!]

  # Check if the user has exceeded rate limits
  # @return [Boolean] true if within limits, false if exceeded
  def within_limits?
    return true unless policy_exists?

    current_count < rate_limit
  end

  # Get current rate limit status for the user
  # @return [Hash] Rate limit status information
  def status
    if policy_exists?
      {
        within_limits: within_limits?,
        current_count: current_count,
        limit: rate_limit,
        reset_at: Time.zone.at(next_window_start)
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
    # Count conversations assigned to this user in the current time window
    # from this inbox
    window_start = Time.zone.at(current_window)

    Conversation
      .where(inbox_id: inbox.id)
      .where(assignee_id: user.id)
      .where('updated_at >= ?', window_start)
      .where.not(assignee_id: nil)
      .count
  end

  def rate_limit
    policy&.fair_distribution_limit || 10
  end

  def time_window
    policy&.fair_distribution_window || 3600
  end

  def current_window
    (Time.current.to_i / time_window) * time_window
  end

  def next_window_start
    current_window + time_window
  end
end
