class AgentBotPolicy < ApplicationPolicy
  def index?
    # Agent bots can be read by all agents (needed for inbox assignment)
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    # CommMate: Allow administrators or users with settings_agent_bots_manage permission
    @account_user.administrator? || has_agent_bots_manage_permission?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    # CommMate: Allow administrators or users with settings_agent_bots_manage permission
    @account_user.administrator? || has_agent_bots_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_agent_bots_manage permission
    @account_user.administrator? || has_agent_bots_manage_permission?
  end

  def avatar?
    # CommMate: Allow administrators or users with settings_agent_bots_manage permission
    @account_user.administrator? || has_agent_bots_manage_permission?
  end

  def reset_access_token?
    # CommMate: Allow administrators or users with settings_agent_bots_manage permission
    @account_user.administrator? || has_agent_bots_manage_permission?
  end

  private

  # CommMate: Check if user has settings_agent_bots_manage permission
  def has_agent_bots_manage_permission?
    @account_user.permissions.include?('settings_agent_bots_manage')
  end
end
