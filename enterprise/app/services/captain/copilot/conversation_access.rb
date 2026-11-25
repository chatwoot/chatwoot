module Captain::Copilot::ConversationAccess
  private

  def accessible_conversation(account:, user:, display_id:)
    accessible_conversations(account: account, user: user).find_by(display_id: display_id)
  end

  def accessible_conversations(account:, user:)
    conversations = account.conversations
    return conversations.none if user.blank?

    account_user = account.account_users.find_by(user_id: user.id)
    return conversations.none if account_user.blank?

    conversations = base_accessible_conversations(conversations, account, user, account_user)
    return conversations if account_user.custom_role_id.blank?

    filter_by_custom_role(conversations, account, user, account_user)
  end

  def base_accessible_conversations(conversations, account, user, account_user)
    return conversations if account_user.administrator?

    inbox_conversations = conversations.where(inbox_id: user.inboxes.where(account_id: account.id).select(:id))
    team_conversations = conversations.where(team_id: user.teams.where(account_id: account.id).select(:id))

    inbox_conversations.or(team_conversations)
  end

  def filter_by_custom_role(conversations, account, user, account_user)
    permissions = account_user.custom_role&.permissions || []
    return conversations if permissions.include?('conversation_manage')

    permission_scopes = custom_role_permission_scopes(conversations, account, user, permissions)
    return conversations.none if permission_scopes.empty?

    permission_scopes.reduce { |scope, permission_scope| scope.or(permission_scope) }
  end

  def custom_role_permission_scopes(conversations, account, user, permissions)
    scopes = []

    if permissions.include?('conversation_unassigned_manage')
      scopes << conversations
                .unassigned
                .or(conversations.assigned_to(user))
    end

    if permissions.include?('conversation_participating_manage')
      participant_ids = ConversationParticipant.where(account_id: account.id, user_id: user.id).select(:conversation_id)
      scopes << conversations.where(assignee_id: user.id).or(conversations.where(id: participant_ids))
    end

    scopes
  end
end
