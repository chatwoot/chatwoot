class UserAssignmentPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    account_user.administrator? || record.user_id == user.id
  end

  def create?
    # Only Account Admins can assign templates to users
    account_user.administrator?
  end

  def destroy?
    account_user.administrator?
  end

  def update?
    # Agents can activate their own, Admins can manage all
    account_user.administrator? || record.user_id == user.id
  end

  def available_templates?
    account_user.administrator?
  end
end
