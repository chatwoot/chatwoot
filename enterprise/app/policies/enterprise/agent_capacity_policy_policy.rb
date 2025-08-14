class Enterprise::AgentCapacityPolicyPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def assign_user?
    @account_user.administrator?
  end

  def unassign_user?
    @account_user.administrator?
  end

  def update_inbox_limit?
    @account_user.administrator?
  end
end
