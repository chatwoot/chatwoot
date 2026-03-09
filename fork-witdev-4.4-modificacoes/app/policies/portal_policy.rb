class PortalPolicy < ApplicationPolicy
  def index?
    @account.users.include?(@user)
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account.users.include?(@user)
  end

  def edit?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def logo?
    @account_user.administrator?
  end
end

PortalPolicy.prepend_mod_with('PortalPolicy')
