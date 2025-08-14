class Api::V1::Accounts::AssignmentPolicies::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_assignment_policy
  before_action :fetch_inbox, only: [:create, :destroy]
  before_action -> { check_authorization(AssignmentPolicy) }

  def index
    @inboxes = @assignment_policy.inboxes
  end

  def create
    @inbox.inbox_assignment_policy&.destroy
    @inbox_assignment_policy = @inbox.create_inbox_assignment_policy!(assignment_policy: @assignment_policy)
  end

  def destroy
    @inbox.inbox_assignment_policy&.destroy!
    head :ok
  end

  private

  def fetch_assignment_policy
    @assignment_policy = Current.account.assignment_policies.find(params[:assignment_policy_id])
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id] || params[:inbox_id])
  end
end
