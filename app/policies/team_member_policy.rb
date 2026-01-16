class TeamMemberPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    # CommMate: Allow administrators or users with settings_teams_manage permission
    @account_user.administrator? || has_teams_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_teams_manage permission
    @account_user.administrator? || has_teams_manage_permission?
  end

  def update?
    # CommMate: Allow administrators or users with settings_teams_manage permission
    @account_user.administrator? || has_teams_manage_permission?
  end

  private

  # CommMate: Check if user has settings_teams_manage permission
  def has_teams_manage_permission?
    @account_user.permissions.include?('settings_teams_manage')
  end
end
