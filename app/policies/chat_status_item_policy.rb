class ChatStatusItemPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end
end
