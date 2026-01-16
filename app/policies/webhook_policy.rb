class WebhookPolicy < ApplicationPolicy
  def index?
    # CommMate: Allow administrators or users with settings_integrations_manage permission
    @account_user.administrator? || has_integrations_manage_permission?
  end

  def update?
    # CommMate: Allow administrators or users with settings_integrations_manage permission
    @account_user.administrator? || has_integrations_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_integrations_manage permission
    @account_user.administrator? || has_integrations_manage_permission?
  end

  def create?
    # CommMate: Allow administrators or users with settings_integrations_manage permission
    @account_user.administrator? || has_integrations_manage_permission?
  end

  private

  # CommMate: Check if user has settings_integrations_manage permission
  def has_integrations_manage_permission?
    @account_user.permissions.include?('settings_integrations_manage')
  end
end
