module Enterprise::ConversationPolicy
  def show?
    return false unless super
    return true unless custom_role_permissions?

    permissions = custom_role_permissions
    return true if manage_all_conversations?(permissions)
    return true if permits_unassigned_manage?(permissions)

    permits_participating?(permissions)
  end

  private

  def manage_all_conversations?(permissions)
    permissions.include?('conversation_manage')
  end

  def permits_unassigned_manage?(permissions)
    return false unless permissions.include?('conversation_unassigned_manage')

    unassigned_conversation? || assigned_to_user?
  end

  def permits_participating?(permissions)
    return false unless permissions.include?('conversation_participating_manage')

    assigned_to_user? || participant?
  end

  def unassigned_conversation?
    record.assignee_id.nil?
  end

  def custom_role_permissions?
    account_user&.custom_role_id.present?
  end

  def custom_role_permissions
    account_user&.custom_role&.permissions || []
  end
end
