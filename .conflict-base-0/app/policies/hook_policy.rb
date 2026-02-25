class HookPolicy < ApplicationPolicy
  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def process_event?
    true
  end

  def destroy?
    @account_user.administrator?
  end
end
