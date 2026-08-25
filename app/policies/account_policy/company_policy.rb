class AccountPolicy::CompanyPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    index?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(account: @account)
    end
  end
end
