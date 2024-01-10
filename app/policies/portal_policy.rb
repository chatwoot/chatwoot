class PortalPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator? || portal_member?
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

  def logo?
    @account_user.administrator?
  end

  private

  def portal_member?
    @record.first.members.include?(@user)
  end
end
