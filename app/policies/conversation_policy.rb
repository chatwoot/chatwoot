class ConversationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope if user.is_a?(AgentBot)
      return scope.none if account.blank?

      conversations = scope.where(account_id: account.id)
      Conversations::PermissionFilterService.new(conversations, user, account).perform
    end
  end

  def index?
    true
  end

  def destroy?
    @account_user&.administrator?
  end
end
