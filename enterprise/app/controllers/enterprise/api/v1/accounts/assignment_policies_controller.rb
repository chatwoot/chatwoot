module Enterprise::Api::V1::Accounts::AssignmentPoliciesController
  private

  def assignment_policy_params
    super.merge(params.require(:assignment_policy).permit(:eligible_custom_role_id))
  end
end
