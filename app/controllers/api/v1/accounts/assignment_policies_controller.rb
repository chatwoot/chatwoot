# frozen_string_literal: true

class Api::V1::Accounts::AssignmentPoliciesController < Api::V1::Accounts::BaseController
  before_action :fetch_assignment_policy, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @assignment_policies = Current.account.assignment_policies.includes(:inboxes)
    render json: { assignment_policies: serialize_assignment_policies(@assignment_policies) }
  end

  def show
    render json: { assignment_policy: serialize_assignment_policy(@assignment_policy) }
  end

  def create
    @assignment_policy = Current.account.assignment_policies.build(assignment_policy_params)

    if @assignment_policy.save
      render json: { assignment_policy: serialize_assignment_policy(@assignment_policy) }, status: :created
    else
      render json: { errors: @assignment_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @assignment_policy.update(assignment_policy_params)
      render json: { assignment_policy: serialize_assignment_policy(@assignment_policy) }
    else
      render json: { errors: @assignment_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @assignment_policy.destroy
      head :ok
    else
      render json: { errors: @assignment_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def fetch_assignment_policy
    @assignment_policy = Current.account.assignment_policies.find(params[:id])
  end

  def assignment_policy_params
    params.require(:assignment_policy).permit(
      :name, :description, :assignment_order, :conversation_priority,
      :fair_distribution_limit, :fair_distribution_window, :enabled
    )
  end

  def serialize_assignment_policy(policy)
    {
      id: policy.id,
      name: policy.name,
      description: policy.description,
      assignment_order: policy.assignment_order,
      conversation_priority: policy.conversation_priority,
      fair_distribution_limit: policy.fair_distribution_limit,
      fair_distribution_window: policy.fair_distribution_window,
      enabled: policy.enabled,
      inbox_count: policy.inboxes.count,
      inboxes: policy.inboxes.map { |inbox| { id: inbox.id, name: inbox.name } },
      created_at: policy.created_at,
      updated_at: policy.updated_at
    }
  end

  def serialize_assignment_policies(policies)
    policies.map { |policy| serialize_assignment_policy(policy) }
  end

  def check_authorization
    authorize(AssignmentPolicy)
  end
end
