class ProductPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end
end
