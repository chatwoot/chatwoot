# frozen_string_literal: true

module InboxAgentAvailability
  extend ActiveSupport::Concern

  def available_agents(options = {})
    options = { check_capacity: true }.merge(options)

    # Get online agent IDs
    online_agent_ids = fetch_online_agent_ids
    return inbox_members.none if online_agent_ids.empty?

    # Base query - only online agents
    scope = build_online_agents_scope(online_agent_ids)

    # Apply filters
    apply_agent_filters(scope, options)
  end

  def member_ids_with_assignment_capacity
    return member_ids unless assignment_v2_enabled? && enterprise_capacity_enabled?

    available_agents(check_capacity: true).pluck(:user_id)
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

    # Apply capacity filtering for enterprise accounts
    scope = filter_by_capacity(scope) if options[:check_capacity] && enterprise_capacity_enabled?

    # Apply rate limiting if implemented
    scope = filter_by_rate_limits(scope) if options[:check_rate_limits] && defined?(AssignmentV2::RateLimiter)

    # Exclude agents who are on leave
    scope = filter_agents_on_leave(scope) if options[:exclude_on_leave] != false

    scope
  end

  def fetch_online_agent_ids
    OnlineStatusTracker.get_available_users(account_id)
                       .select { |_key, value| value.eql?('online') }
                       .keys
                       .map(&:to_i)
  end

  def enterprise_capacity_enabled?
    defined?(Enterprise) &&
      account.custom_attributes&.dig('enterprise_features', 'capacity_management').present?
  end

  def filter_by_capacity(inbox_members_scope)
    return inbox_members_scope unless capacity_check_required?

    assignment_counts = fetch_assignment_counts

    inbox_members_scope.select do |inbox_member|
      agent_has_capacity?(inbox_member, assignment_counts)
    end
  end

  def capacity_check_required?
    defined?(Enterprise::InboxCapacityLimit) &&
      account.account_users.joins(:agent_capacity_policy).exists?
  end

  def fetch_assignment_counts
    conversations
      .where(status: :open)
      .where.not(assignee_id: nil)
      .group(:assignee_id)
      .count
  end

  def agent_has_capacity?(inbox_member, assignment_counts)
    user = inbox_member.user
    account_user = account.account_users.find_by(user: user)

    return true unless account_user&.agent_capacity_policy_id

    capacity_limit = fetch_capacity_limit(account_user.agent_capacity_policy_id)
    return true unless capacity_limit&.conversation_limit

    current_count = assignment_counts[user.id] || 0
    current_count < capacity_limit.conversation_limit
  end

  def fetch_capacity_limit(policy_id)
    Enterprise::InboxCapacityLimit
      .where(agent_capacity_policy_id: policy_id)
      .find_by(inbox_id: id)
  end

  def filter_by_rate_limits(inbox_members_scope)
    # Filter out agents who have exceeded rate limits
    return inbox_members_scope unless assignment_policy&.enabled?

    inbox_members_scope.select do |inbox_member|
      rate_limiter = AssignmentV2::RateLimiter.new(inbox: self, user: inbox_member.user)
      rate_limiter.within_limits?
    end
  end

  def filter_agents_on_leave(inbox_members_scope)
    return inbox_members_scope unless defined?(Enterprise::AgentLeave)

    # Filter out agents who are currently on leave
    on_leave_user_ids = Enterprise::AgentLeave
                        .active
                        .where(account_id: account_id)
                        .pluck(:user_id)

    return inbox_members_scope if on_leave_user_ids.empty?

    inbox_members_scope.where.not(user_id: on_leave_user_ids)
  end
end
