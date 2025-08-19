class Api::V1::Accounts::Inboxes::AssignmentPoliciesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :fetch_assignment_policy, only: [:create]
  before_action -> { check_authorization(AssignmentPolicy) }
  before_action :validate_assignment_policy, only: [:show, :destroy]

  def show
    @assignment_policy = @inbox.assignment_policy
  end

  def create
    # There should be only one assignment policy for an inbox.
    # If there is a new request to add an assignment policy, we will
    # delete the old one and attach the new policy
    remove_inbox_assignment_policy
    @inbox_assignment_policy = @inbox.create_inbox_assignment_policy!(assignment_policy: @assignment_policy)
    @assignment_policy = @inbox.assignment_policy
  end

  def destroy
    remove_inbox_assignment_policy
    head :ok
  end

  private

  def remove_inbox_assignment_policy
    @inbox.inbox_assignment_policy&.destroy
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(permitted_params[:inbox_id])
  end

  def fetch_assignment_policy
    @assignment_policy = Current.account.assignment_policies.find(permitted_params[:assignment_policy_id])
  end

  def permitted_params
    params.permit(:assignment_policy_id, :inbox_id)
  end

  def validate_assignment_policy
    return render_not_found_error(I18n.t('errors.assignment_policy.not_found')) unless @inbox.assignment_policy
  end
end
