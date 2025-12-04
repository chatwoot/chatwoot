class AccountEmailTemplatePolicy < ApplicationPolicy
  def index?
    # Account Admins can VIEW (to see what defaults exist)
    user.super_admin? || user.administrator?
  end

  def show?
    user.super_admin? || user.administrator?
  end

  def create?
    # Only Super Admin creates content
    user.super_admin?
  end

  def update?
    user.super_admin?
  end

  def destroy?
    user.super_admin?
  end
end
