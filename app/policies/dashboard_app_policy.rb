class DashboardAppPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    administrator?
  end

  def update?
    administrator?
  end

  def destroy?
    administrator?
  end

  private

  def administrator?
    return account_user.administrator? if account_user

    account.account_users.administrator.exists?(user_id: user&.id)
  end
end
