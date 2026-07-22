module Enterprise::Api::V1::Accounts::AgentsController
  def create
    super
    associate_agent_with_custom_role
  end

  def update
    super
    associate_agent_with_custom_role
  end

  private

  def associate_agent_with_custom_role
    # `super` may render payment-required without creating an agent (seat limit lost in the locked check);
    # skip the association so that response is preserved instead of raising on a nil agent.
    return if @agent.blank?

    @agent.current_account_user.update!(custom_role_id: params[:custom_role_id])
  end
end
