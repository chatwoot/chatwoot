class PortalPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || is_portal_member?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator? || is_portal_member?
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

  def add_members?
    @account_user.administrator?
  end

  private

  def is_portal_member?
    @portal.members.include?(@account_user)
  end
end
