module Enterprise::InboxAgentAvailability
  extend ActiveSupport::Concern

  def member_ids_with_assignment_capacity
    return member_ids unless capacity_filtering_enabled?

    # Get online agents with capacity
    agents = available_agents
    agents = filter_by_capacity(agents)
    agents.map(&:user_id)
  end

  private

  def filter_by_capacity(inbox_members_scope)
    return inbox_members_scope unless capacity_filtering_enabled?

    inbox_members_scope.select do |inbox_member|
      capacity_service.agent_has_capacity?(inbox_member.user, self)
    end
  end

  def capacity_filtering_enabled?
    account.feature_enabled?('assignment_v2') &&
      account.account_users.joins(:agent_capacity_policy).exists?
  end

  def capacity_service
    @capacity_service ||= Enterprise::AutoAssignment::CapacityService.new
  end
end
