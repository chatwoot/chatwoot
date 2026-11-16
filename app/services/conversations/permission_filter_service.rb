class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account, :access_context

  def initialize(conversations, user, account, plan_hint_selective_filter: false, access_context: nil)
    @conversations = conversations
    @user = user
    @account = account
    @plan_hint_selective_filter = plan_hint_selective_filter
    @access_context = access_context
  end

  def perform
    return conversations if user_role == 'administrator'

    accessible_conversations
  end

  private

  def accessible_conversations
    return hinted_accessible_conversations if @plan_hint_selective_filter
    return conversations.where(inbox_id: access_context.inbox_ids) if access_context

    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  # Same rows as accessible_conversations. `inbox_id + 0` keeps the planner from
  # driving the query through an inbox scan, which it grossly misestimates when a
  # highly selective filter (e.g. labels) is present on large accounts (CW-7787).
  def hinted_accessible_conversations
    return Conversation.none if access_context&.inbox_ids == []
    return conversations.where('(conversations.inbox_id + 0) IN (?)', access_context.inbox_ids) if access_context

    conversations.where(
      '(conversations.inbox_id + 0) IN (
        SELECT inbox_members.inbox_id FROM inbox_members
        INNER JOIN inboxes ON inboxes.id = inbox_members.inbox_id
        WHERE inbox_members.user_id = :user_id AND inboxes.account_id = :account_id
      )',
      user_id: user.id, account_id: account.id
    )
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    return access_context.role if access_context

    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
