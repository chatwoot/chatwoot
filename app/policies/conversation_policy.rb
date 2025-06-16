class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def destroy?
    @account_user&.administrator?
  end
end
