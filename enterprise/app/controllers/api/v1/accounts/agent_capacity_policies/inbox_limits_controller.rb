class Api::V1::Accounts::AgentCapacityPolicies::InboxLimitsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action -> { check_authorization(AgentCapacityPolicy) }
  before_action :fetch_policy
  before_action :fetch_inbox, only: [:create]
  before_action :fetch_inbox_limit, only: [:update, :destroy]
  before_action :validate_no_duplicate, only: [:create]

  def create
    @inbox_limit = @agent_capacity_policy.inbox_capacity_limits.create!(
      inbox: @inbox,
      conversation_limit: permitted_params[:conversation_limit]
    )
  end

  def update
    @inbox_limit.update!(conversation_limit: permitted_params[:conversation_limit])
  end

  def destroy
    @inbox_limit.destroy!
    head :no_content
  end

  private

  def fetch_policy
    @agent_capacity_policy = Current.account.agent_capacity_policies.find(params[:agent_capacity_policy_id])
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(permitted_params[:inbox_id])
  end

  def fetch_inbox_limit
    @inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find(params[:id])
  end

  def validate_no_duplicate
    return unless @agent_capacity_policy.inbox_capacity_limits.exists?(inbox: @inbox)

    render_could_not_create_error(I18n.t('agent_capacity_policy.inbox_already_assigned'))
  end

  def permitted_params
    params.permit(:inbox_id, :conversation_limit)
  end
end
