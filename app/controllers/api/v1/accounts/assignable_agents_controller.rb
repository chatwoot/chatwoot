class Api::V1::Accounts::AssignableAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_inboxes

  def index
    agent_ids = @inboxes.map do |inbox|
      authorize inbox, :show?
      member_ids = inbox.members.pluck(:user_id)
      member_ids
    end
    agent_ids = agent_ids.inject(:&)
    agents = Current.account.users.where(id: (agent_ids + team_member_ids))
    @assignable_agents = (agents + Current.account.administrators).uniq
  end

  private

  def fetch_inboxes
    @inboxes = Current.account.inboxes.find(permitted_params[:inbox_ids])
  end

  def team_member_ids
    return [] if permitted_params[:conversation_ids].blank?

    conversations = Current.account.conversations.where(display_id: permitted_params[:conversation_ids])
    team_ids = conversations.map(&:team_id).uniq.compact
    Current.account.teams.where(id: team_ids).map(&:members).map(&:all).flatten.map(&:id).uniq
  end

  def permitted_params
    params.permit(inbox_ids: [], conversation_ids: [])
  end
end
