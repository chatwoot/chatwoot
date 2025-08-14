class Api::V1::Accounts::Inboxes::AssignmentPoliciesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :fetch_assignment_policy, only: [:create]
  before_action :check_authorization

  def show
    @assignment_policy = @inbox.inbox_assignment_policy&.assignment_policy
    render_not_found_error(I18n.t('errors.assignment_policy.not_found')) unless @assignment_policy
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

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def fetch_assignment_policy
    @assignment_policy = Current.account.assignment_policies.find(params[:assignment_policy_id])
  end
end
