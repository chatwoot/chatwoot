class Api::V1::Accounts::AssignableAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_inboxes

  def index
    agent_ids = @inboxes.map do |inbox|
      authorize inbox, :show?
      member_ids = inbox.members.pluck(:user_id)
      member_ids
    end
    agent_ids = agent_ids.inject(:&)
    agents = Current.account.users.where(id: agent_ids)
    agents = filter_by_location(agents) if permitted_params[:location_id].present?

    @assignable_agents = (agents + Current.account.administrators + supervisors_for_inboxes(agent_ids)).uniq
  end

  private

  def fetch_inboxes
    @inboxes = Current.account.inboxes.find(permitted_params[:inbox_ids])
  end

  def permitted_params
    params.permit(:location_id, inbox_ids: [])
  end

  def filter_by_location(agents)
    agents.joins(:account_users)
          .where(account_users: { account_id: Current.account.id, location_id: permitted_params[:location_id] })
  end

  # Only include supervisors whose subordinates are members of the inbox
  def supervisors_for_inboxes(member_ids)
    Current.account.account_users.supervisor.includes(:user).select do |account_user|
      (account_user.subordinate_user_ids & member_ids).any?
    end.map(&:user)
  end
end
