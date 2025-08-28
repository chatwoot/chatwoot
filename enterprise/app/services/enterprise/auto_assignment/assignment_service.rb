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

  # Override to check policy first
  def assignment_enabled?
    return policy.enabled? if policy

    super
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
end
