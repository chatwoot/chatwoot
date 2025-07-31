# frozen_string_literal: true

class Api::V1::Accounts::AgentCapacityPoliciesController < Api::V1::Accounts::BaseController
  before_action :ensure_enterprise_account
  before_action :fetch_agent_capacity_policy, only: [:show, :update, :destroy, :set_inbox_limit, :remove_inbox_limit, :assign_user, :remove_user]
  before_action :check_authorization

  def index
    @agent_capacity_policies = Enterprise::AgentCapacityPolicy.where(account_id: Current.account.id).includes(:users, :inbox_capacity_limits)
    render json: { agent_capacity_policies: serialize_agent_capacity_policies(@agent_capacity_policies) }
  end

  def show
    render json: { agent_capacity_policy: serialize_agent_capacity_policy(@agent_capacity_policy) }
  end

  def create
    @agent_capacity_policy = Enterprise::AgentCapacityPolicy.new(agent_capacity_policy_params)
    @agent_capacity_policy.account_id = Current.account.id

    if @agent_capacity_policy.save
      render json: { agent_capacity_policy: serialize_agent_capacity_policy(@agent_capacity_policy) }, status: :created
    else
      render json: { errors: @agent_capacity_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @agent_capacity_policy.update(agent_capacity_policy_params)
      render json: { agent_capacity_policy: serialize_agent_capacity_policy(@agent_capacity_policy) }
    else
      render json: { errors: @agent_capacity_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @agent_capacity_policy.destroy
      head :ok
    else
      render json: { errors: @agent_capacity_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Set inbox capacity limit for a policy
  def set_inbox_limit
    inbox = Current.account.inboxes.find(params[:inbox_id])
    inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find_or_initialize_by(inbox: inbox)

    if inbox_limit.update(conversation_limit: params[:conversation_limit])
      render json: {
        inbox_capacity_limit: serialize_inbox_capacity_limit(inbox_limit)
      }
    else
      render json: { errors: inbox_limit.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Remove inbox capacity limit from a policy
  def remove_inbox_limit
    inbox = Current.account.inboxes.find(params[:inbox_id])
    inbox_limit = @agent_capacity_policy.inbox_capacity_limits.find_by(inbox: inbox)

    if inbox_limit
      if inbox_limit.destroy
        head :ok
      else
        render json: { errors: inbox_limit.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Inbox limit not found' }, status: :not_found
    end
  end

  # Assign a user to a capacity policy
  def assign_user
    user = Current.account.users.find(params[:user_id])
    account_user = Current.account.account_users.find_by!(user: user)

    # Update the account_user to assign to this policy
    if account_user.update(agent_capacity_policy_id: @agent_capacity_policy.id)
      render json: {
        message: 'User assigned successfully',
        user_id: user.id,
        agent_capacity_policy_id: @agent_capacity_policy.id
      }
    else
      render json: { errors: account_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Remove a user from a capacity policy
  def remove_user
    user = Current.account.users.find(params[:user_id])
    account_user = Current.account.account_users.find_by!(user: user)

    if account_user.agent_capacity_policy_id == @agent_capacity_policy.id
      if account_user.update(agent_capacity_policy_id: nil)
        head :ok
      else
        render json: { errors: account_user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'User not assigned to this policy' }, status: :not_found
    end
  end

  # Get current capacity status for an agent
  def agent_capacity
    user = Current.account.users.find(params[:agent_id])
    inbox = params[:inbox_id] ? Current.account.inboxes.find(params[:inbox_id]) : nil

    capacity_service = Enterprise::AssignmentV2::CapacityService.new
    capacity_data = if inbox
                      capacity_service.get_agent_capacity(user, inbox)
                    else
                      capacity_service.get_agent_overall_capacity(user)
                    end

    render json: { agent_capacity: capacity_data }
  end

  private

  def ensure_enterprise_account
    return if Current.account.feature_enabled?(:enterprise_agent_capacity)

    render json: {
      error: 'Agent capacity policies are only available for enterprise accounts'
    }, status: :forbidden
  end

  def fetch_agent_capacity_policy
    @agent_capacity_policy = Enterprise::AgentCapacityPolicy.where(account_id: Current.account.id).includes(:users,
                                                                                                            inbox_capacity_limits: :inbox).find(params[:id])
  end

  def agent_capacity_policy_params
    params.require(:agent_capacity_policy).permit(:name, :description, exclusion_rules: {})
  end

  def check_authorization
    authorize(Enterprise::AgentCapacityPolicy) if defined?(Enterprise::AgentCapacityPolicy)
  end

  def serialize_agent_capacity_policy(policy)
    {
      id: policy.id,
      name: policy.name,
      description: policy.description,
      exclusion_rules: policy.exclusion_rules,
      user_count: policy.users.count,
      inbox_limit_count: policy.inbox_capacity_limits.count,
      inbox_limits: policy.inbox_capacity_limits.map { |limit| serialize_inbox_capacity_limit(limit) },
      users: policy.users.map { |user| { id: user.id, name: user.name, email: user.email, avatar_url: user.avatar_url } },
      created_at: policy.created_at,
      updated_at: policy.updated_at
    }
  end

  def serialize_agent_capacity_policies(policies)
    policies.map { |policy| serialize_agent_capacity_policy(policy) }
  end

  def serialize_inbox_capacity_limit(limit)
    {
      id: limit.id,
      inbox_id: limit.inbox_id,
      inbox_name: limit.inbox.name,
      conversation_limit: limit.conversation_limit,
      created_at: limit.created_at,
      updated_at: limit.updated_at
    }
  end
end
