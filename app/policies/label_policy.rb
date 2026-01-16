class LabelPolicy < ApplicationPolicy
  def index?
    # Labels can be read by all agents (needed for labeling conversations)
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    # CommMate: Allow administrators or users with settings_labels_manage permission
    @account_user.administrator? || has_labels_manage_permission?
  end

  def show?
    # CommMate: Allow administrators or users with settings_labels_manage permission
    @account_user.administrator? || has_labels_manage_permission?
  end

  def create?
    # CommMate: Allow administrators or users with settings_labels_manage permission
    @account_user.administrator? || has_labels_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_labels_manage permission
    @account_user.administrator? || has_labels_manage_permission?
  end

  private

  # CommMate: Check if user has settings_labels_manage permission
  def has_labels_manage_permission?
    @account_user.permissions.include?('settings_labels_manage')
  end
end
