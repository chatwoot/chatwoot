class TaskTemplatePolicy < ApplicationPolicy
  def index?
    agent_or_admin?
  end

  def show?
    agent_or_admin?
  end

  def create?
    account_user&.administrator?
  end

  def update?
    account_user&.administrator?
  end

  def destroy?
    account_user&.administrator?
  end

  private

  def agent_or_admin?
    account_user&.administrator? || account_user&.agent?
  end
end
