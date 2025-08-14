# frozen_string_literal: true

class Api::V1::Accounts::InboxAssignmentPoliciesController < Api::V1::Accounts::BaseController
  include RequestExceptionHandler
  before_action :fetch_assignment_policy, only: [:index, :create, :destroy]
  before_action :fetch_inbox, only: [:show, :create, :destroy]
  before_action :check_authorization

  # GET /api/v1/accounts/{account_id}/assignment_policies/{assignment_policy_id}/inboxes
  def index
    @inboxes = @assignment_policy.inboxes
  end

  # GET /api/v1/accounts/{account_id}/inboxes/{inbox_id}/assignment_policy
  def show
    @inbox_assignment_policy = @inbox.inbox_assignment_policy
    render_not_found_error(I18n.t('errors.assignment_policy.not_found')) unless @inbox_assignment_policy
  end

  # POST /api/v1/accounts/{account_id}/assignment_policies/{assignment_policy_id}/inboxes
  def create
    # Remove existing assignment if any
    @inbox.inbox_assignment_policy&.destroy

    @inbox_assignment_policy = @inbox.build_inbox_assignment_policy(assignment_policy: @assignment_policy)
    @inbox_assignment_policy.save!

    render :create, status: :created
  end

  # DELETE /api/v1/accounts/{account_id}/assignment_policies/{assignment_policy_id}/inboxes/{inbox_id}
  def destroy
    @inbox_assignment_policy = @inbox.inbox_assignment_policy

    if @inbox_assignment_policy&.assignment_policy_id == @assignment_policy.id
      @inbox_assignment_policy.destroy!
      head :ok
    else
      render_not_found_error(I18n.t('errors.assignment_policy.not_found'))
    end
  end

  private

  def fetch_assignment_policy
    return unless params[:assignment_policy_id]

    @assignment_policy = Current.account.assignment_policies.find(params[:assignment_policy_id])
  end

  def fetch_inbox
    @inbox = if params[:inbox_id]
               Current.account.inboxes.find(params[:inbox_id])
             elsif params[:id]
               Current.account.inboxes.find(params[:id])
             else
               Current.account.inboxes.find(inbox_params[:inbox_id])
             end
  end

  def inbox_params
    params.permit(:inbox_id)
  end

  def check_authorization
    if @assignment_policy
      authorize(AssignmentPolicy)
    elsif @inbox
      authorize(@inbox, :update?)
    end
  end
end
