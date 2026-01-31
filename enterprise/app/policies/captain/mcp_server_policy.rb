class Captain::McpServerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
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

  def connect?
    @account_user.administrator?
  end

  def disconnect?
    @account_user.administrator?
  end

  def refresh?
    @account_user.administrator?
  end
end
