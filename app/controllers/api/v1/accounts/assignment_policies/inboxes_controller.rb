class Api::V1::Accounts::AssignmentPolicies::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_assignment_policy
  before_action -> { check_authorization(AssignmentPolicy) }

  def index
    @inboxes = @assignment_policy.inboxes
  end

  private

  def fetch_assignment_policy
    @assignment_policy = Current.account.assignment_policies.find(
      params[:assignment_policy_id]
    )
  end

  def permitted_params
    params.permit(:assignment_policy_id)
  end
end
