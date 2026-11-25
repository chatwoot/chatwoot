class InternalChat::CategoryPolicy < ApplicationPolicy
  def index?
    agent_or_admin?
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

  def agent_or_admin?
    @account_user.present?
  end

  def administrator?
    @account_user&.administrator?
  end
end

InternalChat::CategoryPolicy.prepend_mod_with('InternalChat::CategoryPolicy')
