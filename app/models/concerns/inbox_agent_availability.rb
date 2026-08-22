module InboxAgentAvailability
  extend ActiveSupport::Concern

  def available_agents
    online_agent_ids = fetch_online_agent_ids
    return inbox_members.none if online_agent_ids.empty?

    inbox_members
      .joins(:user)
      .where(users: { id: online_agent_ids })
      .includes(:user)
  end

  def member_ids_with_assignment_capacity
    return members.ids unless capacity_filtering_enabled?

    agents = available_agents
    return [] if agents.empty?

    # Use batch capacity check to avoid N+1
    users = agents.map(&:user)
    allowed_users = AutoAssignment::CapacityService.new.filter_agents_with_capacity(users, self)
    allowed_ids = allowed_users.map(&:id).to_h { |id| [id, true] }
    agents.select { |im| allowed_ids[im.user_id] }.map(&:user_id)
  end

  private

  def capacity_filtering_enabled?
    account.feature_enabled?('advanced_assignment') &&
      account.account_users.joins(:agent_capacity_policy).exists?
  end

  def fetch_online_agent_ids
    OnlineStatusTracker.get_available_users(account_id)
                       .select { |_key, value| value.eql?('online') }
                       .keys
                       .map(&:to_i)
  end
end

InboxAgentAvailability.prepend_mod_with('InboxAgentAvailability')
