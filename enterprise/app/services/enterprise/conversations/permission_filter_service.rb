module Enterprise::Conversations::PermissionFilterService
  def perform
    account_user = AccountUser.find_by(account_id: account.id, user_id: user.id)
    permissions = account_user&.permissions || []
    user_role = account_user&.role

    # Skip filtering for administrators
    return conversations if user_role == 'administrator'
    # Skip filtering for regular agents (without custom roles/permissions)
    return conversations if user_role == 'agent' && account_user&.custom_role_id.nil?

    filter_by_permissions(permissions)
  end

  private

  def filter_by_permissions(permissions)
    # Permission-based filtering with hierarchy
    # conversation_manage > conversation_unassigned_manage > conversation_participating_manage
    if permissions.include?('conversation_manage')
      conversations
    elsif permissions.include?('conversation_unassigned_manage')
      filter_unassigned_and_mine
    elsif permissions.include?('conversation_participating_manage')
      conversations.assigned_to(user)
    else
      Conversation.none
    end
  end

  def filter_unassigned_and_mine
    mine = conversations.assigned_to(user)
    unassigned = conversations.unassigned

    Conversation.from("(#{mine.to_sql} UNION #{unassigned.to_sql}) as conversations")
                .where(account_id: account.id)
  end
end
