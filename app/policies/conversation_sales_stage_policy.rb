class ConversationSalesStagePolicy < ApplicationPolicy
  def show?
    conversation_access?
  end

  def update?
    conversation_access?
  end

  def destroy?
    conversation_access?
  end

  private

  def conversation_access?
    return false unless user.present? && record.present?

    user.account_users.exists?(account_id: record.account_id) &&
      (user.permission.conversation_access? || user.assigned_conversations.exists?(id: record.id))
  end
end