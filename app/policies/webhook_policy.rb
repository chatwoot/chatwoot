class WebhookPolicy < ApplicationPolicy
  def index?
    @user.administrator?
  end

  def update?
    @user.administrator?
  end

  def destroy?
    @user.administrator?
  end

  def create?
    @user.administrator?
  end
end
