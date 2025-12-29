class FaqItemPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
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

  def toggle_visibility?
    @account_user.administrator?
  end

  def move?
    @account_user.administrator?
  end

  def bulk_delete?
    @account_user.administrator?
  end
end
