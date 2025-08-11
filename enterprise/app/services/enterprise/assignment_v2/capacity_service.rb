# frozen_string_literal: true

class Enterprise::AssignmentV2::CapacityService
  def initialize
    @cache_ttl = 5.minutes
  end

  # Get agent's current capacity status for specific inbox
  def get_agent_capacity(agent, inbox)
    cache_key = capacity_cache_key(agent, inbox)

    cached = Redis::Alfred.hgetall(cache_key)
    return parse_cached_capacity(cached) if cached.present?

    # Cache miss - compute from database
    capacity = compute_agent_capacity(agent, inbox)
    cache_capacity_data(cache_key, capacity)
    capacity
  end

  # Get agent's overall capacity across all inboxes
  def get_agent_overall_capacity(agent)
    account = agent.accounts.first # Assuming we're working within account context
    policy = get_agent_capacity_policy(agent, account)

    return unlimited_capacity_summary unless policy

    capacity_data = build_capacity_data_for_policy(agent, policy)
    build_overall_capacity_response(policy, capacity_data)
  end

  private

  def build_capacity_data_for_policy(agent, policy)
    inboxes_data = []
    total_current = 0
    total_limit = 0

    policy.inbox_capacity_limits.includes(:inbox).each do |inbox_limit|
      inbox_data = build_inbox_capacity_data(agent, inbox_limit, policy)

      total_current += inbox_data[:current_assignments]
      total_limit += inbox_data[:conversation_limit]
      inboxes_data << inbox_data
    end

    {
      inboxes: inboxes_data,
      total_current: total_current,
      total_limit: total_limit
    }
  end

  def build_inbox_capacity_data(agent, inbox_limit, policy)
    inbox = inbox_limit.inbox
    current = count_current_assignments(agent, inbox, policy)
    limit = inbox_limit.conversation_limit

    {
      inbox_id: inbox.id,
      inbox_name: inbox.name,
      current_assignments: current,
      conversation_limit: limit,
      available_capacity: [limit - current, 0].max
    }
  end

  def build_overall_capacity_response(policy, capacity_data)
    {
      policy_id: policy.id,
      policy_name: policy.name,
      total_current_assignments: capacity_data[:total_current],
      total_conversation_limit: capacity_data[:total_limit],
      total_available_capacity: [capacity_data[:total_limit] - capacity_data[:total_current], 0].max,
      exclusion_rules: policy.exclusion_rules,
      inboxes: capacity_data[:inboxes]
    }
  end

  def compute_agent_capacity(agent, inbox)
    account = inbox.account
    policy = get_agent_capacity_policy(agent, account)

    return unlimited_capacity if policy.nil?

    inbox_limit = policy.inbox_capacity_limits.find_by(inbox: inbox)
    return unlimited_capacity if inbox_limit.nil?

    current_assignments = count_current_assignments(agent, inbox, policy)

    {
      total_capacity: inbox_limit.conversation_limit,
      current_assignments: current_assignments,
      available_capacity: [inbox_limit.conversation_limit - current_assignments, 0].max,
      policy_id: policy.id,
      policy_name: policy.name,
      exclusion_rules: policy.exclusion_rules
    }
  end

  def get_agent_capacity_policy(agent, account)
    account_user = account.account_users.find_by(user: agent)
    return nil unless account_user&.agent_capacity_policy_id

    Enterprise::AgentCapacityPolicy.find_by(id: account_user.agent_capacity_policy_id)
  end

  def count_current_assignments(agent, inbox, policy)
    scope = agent.assigned_conversations
                 .where(inbox: inbox, status: 'open')

    # Apply exclusion rules from policy
    scope = apply_exclusion_rules(scope, policy)
    scope.count
  end

  def apply_exclusion_rules(scope, policy)
    rules = policy.exclusion_rules || {}

    # Exclude conversations with specific labels
    if rules['labels'].present?
      scope = scope.where.not(id:
        ConversationLabel.joins(:label)
                        .where(labels: { title: rules['labels'] })
                        .select(:conversation_id))
    end

    # Exclude conversations older than X hours
    if rules['hours_threshold'].present?
      cutoff = rules['hours_threshold'].hours.ago
      scope = scope.where('conversations.created_at > ?', cutoff)
    end

    scope
  end

  def unlimited_capacity
    {
      total_capacity: Float::INFINITY,
      current_assignments: 0,
      available_capacity: Float::INFINITY,
      policy_id: nil,
      policy_name: 'No capacity policy',
      exclusion_rules: {}
    }
  end

  def unlimited_capacity_summary
    {
      policy_id: nil,
      policy_name: 'No capacity policy',
      total_current_assignments: 0,
      total_conversation_limit: Float::INFINITY,
      total_available_capacity: Float::INFINITY,
      exclusion_rules: {},
      inboxes: []
    }
  end

  def parse_cached_capacity(cached)
    {
      total_capacity: cached['total_capacity'].to_i,
      current_assignments: cached['current_assignments'].to_i,
      available_capacity: cached['available_capacity'].to_i,
      policy_id: cached['policy_id'].presence&.to_i,
      policy_name: cached['policy_name'] || 'No capacity policy',
      exclusion_rules: JSON.parse(cached['exclusion_rules'] || '{}')
    }
  end

  def cache_capacity_data(cache_key, capacity)
    Redis::Alfred.multi do |multi|
      multi.hset(cache_key,
                 'total_capacity', capacity[:total_capacity],
                 'current_assignments', capacity[:current_assignments],
                 'available_capacity', capacity[:available_capacity],
                 'policy_id', capacity[:policy_id],
                 'policy_name', capacity[:policy_name],
                 'exclusion_rules', capacity[:exclusion_rules].to_json)
      multi.expire(cache_key, @cache_ttl)
    end
  end

  def capacity_cache_key(agent, inbox)
    "assignment_v2:capacity:#{agent.id}:#{inbox.id}"
  end
end
