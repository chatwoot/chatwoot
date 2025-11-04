class CannedResponsePolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator? || @account_user.agent?
  end

  def destroy?
    @account_user.administrator? || @account_user.agent?
  end
end
