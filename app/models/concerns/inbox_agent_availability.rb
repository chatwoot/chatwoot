# frozen_string_literal: true

module InboxAgentAvailability
  extend ActiveSupport::Concern

  def available_agents(options = {})
    # Get online agent IDs
    online_agent_ids = fetch_online_agent_ids
    return inbox_members.none if online_agent_ids.empty?

    # Base query - only online agents
    scope = build_online_agents_scope(online_agent_ids)

    # Apply filters
    apply_agent_filters(scope, options)
  end

  def member_ids_with_assignment_capacity
    member_ids
  end

  private

  def build_online_agents_scope(online_agent_ids)
    inbox_members
      .joins(:user)
      .where(users: { id: online_agent_ids })
      .includes(:user)
  end

  def apply_agent_filters(scope, options)
    # Exclude specific users if requested
    scope = scope.where.not(users: { id: options[:exclude_user_ids] }) if options[:exclude_user_ids].present?

    # Apply rate limiting if assignment policy is enabled
    scope = filter_by_rate_limits(scope) if options[:check_rate_limits] && defined?(AssignmentV2::RateLimiter)

    scope
  end

  def fetch_online_agent_ids
    OnlineStatusTracker.get_available_users(account_id)
                       .select { |_key, value| value.eql?('online') }
                       .keys
                       .map(&:to_i)
  end

  def filter_by_rate_limits(inbox_members_scope)
    # Filter out agents who have exceeded rate limits
    return inbox_members_scope unless assignment_policy&.enabled?

    inbox_members_scope.select do |inbox_member|
      rate_limiter = AssignmentV2::RateLimiter.new(inbox: self, user: inbox_member.user)
      rate_limiter.within_limits?
    end
  end
end
