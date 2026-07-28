module Enterprise::Api::V1::Accounts::AgentsController
  def create
    super
    return if @agent.blank?

    associate_agent_with_custom_role
  end

  def update
    super
    associate_agent_with_custom_role
  end

  private

  def associate_agent_with_custom_role
    # Custom roles are a premium feature; ignore custom_role_id assignment when the feature is disabled.
    return unless Current.account.feature_enabled?('custom_roles')

    @agent.current_account_user.update!(custom_role_id: params[:custom_role_id])
  end
end
