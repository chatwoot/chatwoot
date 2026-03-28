class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_role == 'administrator'

    # Apply participating_only filter if enabled for this agent
    return participating_only_conversations if account_user&.participating_only?

    # Default behavior: all conversations in assigned inboxes
    accessible_conversations
  end

  private

  def accessible_conversations
    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  # Filter to only show conversations where the agent is currently assigned
  # More restrictive: agent loses access when conversation is reassigned
  def participating_only_conversations
    accessible_conversations.where(assignee_id: user.id)
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
