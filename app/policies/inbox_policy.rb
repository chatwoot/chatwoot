class InboxPolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.administrator?
        scope.all
      elsif user.agent?
        user.assigned_inboxes
      end
    end
  end

  def index?
    true
  end

  def create?
    @user.administrator?
  end

  def destroy?
    @user.administrator?
  end
end
