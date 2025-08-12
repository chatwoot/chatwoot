class Api::V1::Accounts::Agents::CapacityController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_agent

  def show
    account_user = Current.account.account_users.find_by!(user: @agent)
    capacity_service = Enterprise::AssignmentV2::CapacityService.new(account_user)
    inbox = fetch_inbox

    render json: build_capacity_response(account_user, capacity_service, inbox)
  end

  private

  def fetch_agent
    @agent = Current.account.users.find(params[:id])
  end

  def fetch_inbox
    return if params[:inbox_id].blank?

    Current.account.inboxes.find(params[:inbox_id])
  end

  def build_capacity_response(account_user, capacity_service, inbox)
    response = {
      has_capacity: capacity_service.agent_has_capacity?(inbox),
      overall_capacity: capacity_service.agent_overall_capacity,
      inbox_capacity: inbox ? capacity_service.agent_capacity_for_inbox(inbox) : nil,
      current_conversations_count: account_user.user.assigned_conversations.open.count
    }

    add_inbox_conversations_count(response, account_user, inbox) if inbox
    response
  end

  def add_inbox_conversations_count(response, account_user, inbox)
    response[:inbox_conversations_count] = account_user.user.assigned_conversations.open.where(inbox: inbox).count
  end
end
