# frozen_string_literal: true

class Api::V1::Accounts::InboxAssignmentPoliciesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :check_authorization

  def show
    @inbox_assignment_policy = @inbox.inbox_assignment_policy

    if @inbox_assignment_policy
      render json: {
        inbox_assignment_policy: serialize_inbox_assignment_policy(@inbox_assignment_policy)
      }
    else
      render json: {
        inbox_assignment_policy: nil,
        message: 'No assignment policy assigned to this inbox'
      }
    end
  end

  def create
    # Remove existing assignment if any
    @inbox.inbox_assignment_policy&.destroy

    @assignment_policy = Current.account.assignment_policies.find(params[:assignment_policy_id])
    @inbox_assignment_policy = @inbox.build_inbox_assignment_policy(assignment_policy: @assignment_policy)

    if @inbox_assignment_policy.save
      render json: {
        inbox_assignment_policy: serialize_inbox_assignment_policy(@inbox_assignment_policy)
      }, status: :created
    else
      render json: { errors: @inbox_assignment_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @inbox_assignment_policy = @inbox.inbox_assignment_policy

    if @inbox_assignment_policy
      if @inbox_assignment_policy.destroy
        head :ok
      else
        render json: { errors: @inbox_assignment_policy.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No assignment policy found for this inbox' }, status: :not_found
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def check_authorization
    authorize(@inbox, :update?)
  end

  def serialize_inbox_assignment_policy(inbox_assignment_policy)
    {
      id: inbox_assignment_policy.id,
      inbox_id: inbox_assignment_policy.inbox_id,
      assignment_policy_id: inbox_assignment_policy.assignment_policy_id,
      assignment_policy: {
        id: inbox_assignment_policy.assignment_policy.id,
        name: inbox_assignment_policy.assignment_policy.name,
        description: inbox_assignment_policy.assignment_policy.description,
        assignment_order: inbox_assignment_policy.assignment_policy.assignment_order,
        conversation_priority: inbox_assignment_policy.assignment_policy.conversation_priority,
        fair_distribution_limit: inbox_assignment_policy.assignment_policy.fair_distribution_limit,
        fair_distribution_window: inbox_assignment_policy.assignment_policy.fair_distribution_window,
        enabled: inbox_assignment_policy.assignment_policy.enabled
      },
      created_at: inbox_assignment_policy.created_at,
      updated_at: inbox_assignment_policy.updated_at
    }
  end
end
