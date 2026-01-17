# CommMate: Updated permission filter service to support per-user conversation permissions.
#
# Permission model (permissions stack):
# - Basic Agent: Only sees conversations assigned to them
# - + conversation_participating_manage: Also sees conversations where they participate
# - + conversation_unassigned_manage: Also sees unassigned conversations
# - conversation_manage: Sees all conversations (within accessible inboxes)
# - Administrator: Sees all conversations
#
# Important: This is the source of truth for server-side filtering. Frontend should not re-filter.
#
class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if administrator?

    # Always restrict to inboxes the agent can access.
    base = accessible_conversations

    # Full access within accessible inboxes.
    return base if permission?('conversation_manage')

    # Basic: assigned to me
    visible = base.where(assignee_id: user.id)

    # + Unassigned
    visible = visible.or(base.unassigned) if permission?('conversation_unassigned_manage')

    # + Participating (participant, not necessarily assignee)
    if permission?('conversation_participating_manage')
      participating_ids = ConversationParticipant.where(user_id: user.id).select(:conversation_id)
      visible = visible.or(base.where(id: participating_ids))
    end

    visible
  end

  private

  # Keep this method name for compatibility with Enterprise prepend modules.
  def accessible_conversations
    @accessible_conversations ||= conversations.where(inbox_id: accessible_inbox_ids)
  end

  def accessible_inbox_ids
    # Prefer assigned_inboxes (Chatwoot semantics: inbox memberships).
    user.assigned_inboxes.where(account_id: account.id).select(:id)
  end

  # Keep these methods for compatibility with Enterprise prepend modules.
  def filter_unassigned_and_mine
    mine = accessible_conversations.assigned_to(user)
    unassigned = accessible_conversations.unassigned

    Conversation.from("(#{mine.to_sql} UNION #{unassigned.to_sql}) as conversations")
                .where(account_id: account.id)
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end

  def administrator?
    account_user&.administrator?
  end

  def permissions
    @permissions ||= account_user&.permissions || []
  end

  def permission?(permission)
    permissions.include?(permission)
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
