class UserPolicy < ApplicationPolicy
  def index?
    true
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

  def bulk_create?
    @account_user.administrator?
  end

  def inboxes?
    @account_user.administrator?
  end

  def teams?
    @account_user.administrator?
  end
end
