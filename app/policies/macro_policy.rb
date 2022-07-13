class MacroPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def create?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def show?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def update?
    @account_user.administrator? || @account.users.include?(@user)
  end

  def destroy?
    @account_user.administrator? || @account.users.include?(@user)
  end
end
