class AutomationRulePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def attach_file?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def clone?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
