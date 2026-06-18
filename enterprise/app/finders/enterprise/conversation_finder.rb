module Enterprise::ConversationFinder
  def filter_by_conversation_type
    return super unless params[:conversation_type] == 'participating' && custom_role_participating_permission?

    @conversations = participating_visible_conversations.where(
      id: current_user.participating_conversations.where(account_id: current_account.id).select(:id)
    )
  end

  def conversations_base_query
    current_account.feature_enabled?('sla') ? super.includes(:applied_sla, :sla_events) : super
  end

  private

  def participating_visible_conversations
    conversations = current_account.conversations
    conversations = conversations.where(inbox_id: @inbox_ids) if params[:inbox_id]
    return conversations if account_user&.administrator?

    conversations.where(inbox: current_user.inboxes.where(account_id: current_account.id))
  end

  def custom_role_participating_permission?
    account_user&.agent? && account_user.custom_role_id.present? && account_user.permissions.include?('conversation_participating_manage')
  end

  def account_user
    @account_user ||= current_account.account_users.find_by(user_id: current_user.id)
  end
end
