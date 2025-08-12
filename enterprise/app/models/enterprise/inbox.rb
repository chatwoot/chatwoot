module Enterprise::Inbox
  def member_ids_with_assignment_capacity
    return super unless enable_auto_assignment?

    member_ids = apply_max_assignment_limit(super)
    apply_capacity_policy_filter(member_ids)
  end

  def available_agents(options = {})
    agents = super(options)

    # Apply capacity filtering if requested and assignment policy is enabled
    agents = filter_agents_by_capacity(agents) if options[:check_capacity] && assignment_policy&.enabled?

    agents
  end

  def active_bot?
    super || captain_active?
  end

  def captain_active?
    captain_assistant.present? && more_responses?
  end

  private

  def filter_agents_by_capacity(inbox_members_scope)
    inbox_members_scope.select do |inbox_member|
      account_user = AccountUser.find_by(account: account, user: inbox_member.user)
      next true if account_user&.agent_capacity_policy.blank?

      capacity_service = Enterprise::AssignmentV2::CapacityService.new(account_user)
      capacity_service.agent_has_capacity?(self)
    end
  end

  def apply_max_assignment_limit(member_ids)
    max_assignment_limit = auto_assignment_config['max_assignment_limit']
    return member_ids if max_assignment_limit.blank?

    overloaded_agent_ids = get_agent_ids_over_assignment_limit(max_assignment_limit)
    member_ids - overloaded_agent_ids
  end

  def apply_capacity_policy_filter(member_ids)
    return member_ids unless assignment_policy&.enabled?

    account_users = AccountUser.where(account_id: account_id, user_id: member_ids)
    account_users.select do |account_user|
      next true if account_user.agent_capacity_policy.blank?

      capacity_service = Enterprise::AssignmentV2::CapacityService.new(account_user)
      capacity_service.agent_has_capacity?(self)
    end.map(&:user_id)
  end

  def more_responses?
    account.usage_limits[:captain][:responses][:current_available].positive?
  end

  def get_agent_ids_over_assignment_limit(limit)
    conversations.open.select(:assignee_id).group(:assignee_id).having("count(*) >= #{limit.to_i}").filter_map(&:assignee_id)
  end

  def ensure_valid_max_assignment_limit
    return if auto_assignment_config['max_assignment_limit'].blank?
    return if auto_assignment_config['max_assignment_limit'].to_i.positive?

    errors.add(:auto_assignment_config, 'max_assignment_limit must be greater than 0')
  end
end
