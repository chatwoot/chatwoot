# CommMate: Policy for Custom Attribute Definitions
# Allows administrators or users with settings_custom_attributes_manage permission
class CustomAttributeDefinitionPolicy < ApplicationPolicy
  def index?
    # Allow all agents to read custom attribute definitions (needed for forms)
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    # Allow all agents to read custom attribute definitions (needed for forms)
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator? || has_custom_attributes_manage_permission?
  end

  def update?
    @account_user.administrator? || has_custom_attributes_manage_permission?
  end

  def destroy?
    @account_user.administrator? || has_custom_attributes_manage_permission?
  end

  private

  def has_custom_attributes_manage_permission?
    @account_user.permissions.include?('settings_custom_attributes_manage')
  end
end
