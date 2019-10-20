class ContactPolicy < ApplicationPolicy
  def index?
    @user.administrator?
  end

  def update?
    @user.administrator?
  end

  def show?
    @user.administrator?
  end

  def create?
    true
  end
end
