class CustomFilterPolicy < ApplicationPolicy
  FEATURE = 'custom_filters'.freeze

  def create?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def show?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def index?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def update?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def destroy?
    @account_user.administrator? || can_access?(FEATURE)
  end
end
