class MessagePolicy < ApplicationPolicy
  def update?
    # Allow update if user has access to the conversation
    return false unless @account_user && @user

    # Check if user has access to the conversation through inbox membership
    conversation = @record.conversation
    return false unless conversation

    # Allow if user has access to the inbox
    @user.assigned_inboxes.include?(conversation.inbox) || @account_user.administrator?
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve
      # Return messages from conversations in inboxes the user has access to
      if @account_user&.administrator?
        scope.joins(:conversation).where(conversations: { account_id: @account.id })
      else
        scope.joins(conversation: :inbox)
             .where(conversations: { account_id: @account.id })
             .where(inboxes: { id: @user.assigned_inboxes.select(:id) })
      end
    end
  end
end 