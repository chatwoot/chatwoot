class TeamMemberPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end
end
