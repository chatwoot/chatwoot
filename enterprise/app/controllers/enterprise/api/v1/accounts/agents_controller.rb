module Enterprise::Api::V1::Accounts::AgentsController
  def account_user_attributes
    super + [:custom_role_id]
  end

  def allowed_agent_params
    super + [:custom_role_id]
  end
end
