class Captain::McpServerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def available_tools?
    true
  end

  def discover?
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

  def authorization_url?
    @account_user.administrator?
  end
end
