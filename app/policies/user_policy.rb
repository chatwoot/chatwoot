class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    # CommMate: Allow administrators or users with settings_agents_manage permission
    @account_user.administrator? || has_agents_manage_permission?
  end

  def update?
    # CommMate: Allow administrators or users with settings_agents_manage permission
    @account_user.administrator? || has_agents_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_agents_manage permission
    @account_user.administrator? || has_agents_manage_permission?
  end

  def bulk_create?
    # CommMate: Allow administrators or users with settings_agents_manage permission
    @account_user.administrator? || has_agents_manage_permission?
  end

  private

  # CommMate: Check if user has settings_agents_manage permission
  def has_agents_manage_permission?
    @account_user.permissions.include?('settings_agents_manage')
  end
end
