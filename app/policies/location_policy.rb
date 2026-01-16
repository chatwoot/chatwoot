class LocationPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.supervisor?
  end

  def create?
    @account_user.administrator? || @account_user.supervisor?
  end

  def show?
    @account_user.administrator? || @account_user.supervisor?
  end

  def update?
    @account_user.administrator? || @account_user.supervisor?
  end

  def destroy?
    @account_user.administrator? || @account_user.supervisor?
  end

  def user_locations?
    true
  end
end
