class AutomationRulePolicy < ApplicationPolicy
  def index?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  def create?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  def show?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  def update?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  def clone?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_automation_manage permission
    @account_user.administrator? || has_automation_manage_permission?
  end

  private

  # CommMate: Check if user has settings_automation_manage permission
  def has_automation_manage_permission?
    @account_user.permissions.include?('settings_automation_manage')
  end
end
