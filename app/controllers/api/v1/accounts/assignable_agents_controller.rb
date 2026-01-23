class Api::V1::Accounts::AssignableAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_inboxes

  def index
    agent_ids = @inboxes.map do |inbox|
      authorize inbox, :show?
      # Only include agents who are assignment_eligible
      member_ids = inbox.inbox_members.assignment_eligible.pluck(:user_id)
      member_ids
    end
    agent_ids = agent_ids.inject(:&)
    # Only return assignment-eligible members (no automatic admin inclusion)
    @assignable_agents = Current.account.users.where(id: agent_ids)
  end

  private

  def fetch_inboxes
    @inboxes = Current.account.inboxes.find(permitted_params[:inbox_ids])
  end

  def permitted_params
    params.permit(inbox_ids: [])
  end
end
