module Enterprise::Api::V1::Accounts::ConversationsController
  def permitted_update_params
    super.merge(params.permit(:sla_policy_id))
  end
end
