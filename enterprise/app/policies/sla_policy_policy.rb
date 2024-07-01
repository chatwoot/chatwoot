class SlaPolicyPolicy < ApplicationPolicy
  FEATURE = 'sla_policies'.freeze

  def index?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
