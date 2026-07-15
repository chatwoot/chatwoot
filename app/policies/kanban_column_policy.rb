class KanbanColumnPolicy < ApplicationPolicy
  def index?
    agent_or_administrator?
  end

  def create?
    agent_or_administrator?
  end

  def update?
    agent_or_administrator?
  end

  def destroy?
    agent_or_administrator?
  end

  private

  def agent_or_administrator?
    @account_user.administrator? || @account_user.agent?
  end
end
