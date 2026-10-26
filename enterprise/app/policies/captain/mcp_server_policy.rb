class Captain::McpServerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  # Lists tools by calling the remote server, which only admins need while they pick tools
  def live_tools?
    @account_user.administrator?
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

  def approve_tool?
    @account_user.administrator?
  end
end
