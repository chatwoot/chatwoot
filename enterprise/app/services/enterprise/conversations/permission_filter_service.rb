module Enterprise::Conversations::PermissionFilterService
  def perform
    return filter_by_permissions(permissions) if user_has_custom_role?

    super
  end

  private

  def user_has_custom_role?
    user_role == 'agent' && account_user&.custom_role_id.present?
  end

  def permissions
    account_user&.permissions || []
  end

  def filter_by_permissions(permissions)
    # Permission-based filtering with hierarchy
    # conversation_manage > conversation_unassigned_manage > conversation_participating_manage
    if permissions.include?('conversation_manage')
      accessible_conversations
    elsif permissions.include?('conversation_unassigned_manage')
      filter_unassigned_and_mine
    elsif permissions.include?('conversation_participating_manage')
      filter_participating_and_mine
    else
      Conversation.none
    end
  end

  def filter_unassigned_and_mine
    mine = accessible_conversations.assigned_to(user)
    unassigned = accessible_conversations.unassigned

    Conversation.from("(#{mine.to_sql} UNION #{unassigned.to_sql}) as conversations")
                .where(account_id: account.id)
  end

  def filter_participating_and_mine
    mine = accessible_conversations.assigned_to(user)
    participating = accessible_conversations
                    .joins(:conversation_participants)
                    .where(conversation_participants: { user_id: user.id })

    Conversation.from("(#{mine.to_sql} UNION #{participating.to_sql}) as conversations")
                .where(account_id: account.id)
  end
end
