class AdvancedEmailTemplatePolicy < ApplicationPolicy
  def index?
    # Account Admins need to see these to assign them
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
