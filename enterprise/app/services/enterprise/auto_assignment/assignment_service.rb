module Enterprise::AutoAssignment::AssignmentService
  private

  # Override assignment config to use policy if available
  def assignment_config
    return super unless policy

    {
      'conversation_priority' => policy.conversation_priority,
      'fair_distribution_limit' => policy.fair_distribution_limit,
      'fair_distribution_window' => policy.fair_distribution_window,
      'balanced' => policy.balanced?
    }.compact
  end

  # Extend agent finding to add capacity checks
  def find_available_agent
    agents = filter_agents_by_rate_limit(inbox.available_agents)
    agents = filter_agents_by_capacity(agents) if capacity_filtering_enabled?
    return nil if agents.empty?

    selector = policy&.balanced? ? balanced_selector : round_robin_selector
    selector.select_agent(agents)
  end

  def filter_agents_by_capacity(agents)
    return agents unless capacity_filtering_enabled?

    capacity_service = Enterprise::AutoAssignment::CapacityService.new
    agents.select { |agent_member| capacity_service.agent_has_capacity?(agent_member.user, inbox) }
  end

  def capacity_filtering_enabled?
    account.feature_enabled?('assignment_v2') &&
      account.account_users.joins(:agent_capacity_policy).exists?
  end

  def round_robin_selector
    @round_robin_selector ||= AutoAssignment::RoundRobinSelector.new(inbox: inbox)
  end

  def balanced_selector
    @balanced_selector ||= Enterprise::AutoAssignment::BalancedSelector.new(inbox: inbox)
  end

  def policy
    @policy ||= inbox.assignment_policy
  end

  def account
    inbox.account
  end

  # Override to apply exclusion rules
  def unassigned_conversations(limit)
    scope = inbox.conversations.unassigned.open

    # Apply exclusion rules from capacity policy or assignment policy
    scope = apply_exclusion_rules(scope)

    # Apply conversation priority using enum methods if policy exists
    scope = if policy&.longest_waiting?
              scope.reorder(last_activity_at: :asc, created_at: :asc)
            else
              scope.reorder(created_at: :asc)
            end

    scope.limit(limit)
  end

  def apply_exclusion_rules(scope)
    capacity_policy = inbox.inbox_capacity_limits.first&.agent_capacity_policy
    return scope unless capacity_policy

    exclusion_rules = capacity_policy.exclusion_rules || {}
    scope = apply_label_exclusions(scope, exclusion_rules['excluded_labels'])
    apply_age_exclusions(scope, exclusion_rules['exclude_older_than_hours'])
  end

  def apply_label_exclusions(scope, excluded_labels)
    return scope if excluded_labels.blank?

    scope.tagged_with(excluded_labels, exclude: true, on: :labels)
  end

  def apply_age_exclusions(scope, hours_threshold)
    return scope if hours_threshold.blank?

    hours = hours_threshold.to_i
    return scope unless hours.positive?

    scope.where('conversations.created_at >= ?', hours.hours.ago)
  end
end
