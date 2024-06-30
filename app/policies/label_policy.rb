class LabelPolicy < ApplicationPolicy
  FEATURE = 'labels'.freeze

  def index?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def update?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator? || can_access?(FEATURE)
  end

  def destroy?
    @account_user.administrator?
  end
end
