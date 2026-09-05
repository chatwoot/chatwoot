module CsatAgentScopeConcern
  extend ActiveSupport::Concern

  private

  def apply_agent_csat_scope(relation)
    return relation unless restricted_agent?

    accessible_conversation_ids = Conversations::AgentAccessService.apply_scope(
      Current.account.conversations,
      Current.user,
      Current.account
    ).select(:id)

    relation.where(conversation_id: accessible_conversation_ids)
  end

  def apply_agent_csat_messages_scope(relation)
    return relation unless restricted_agent?

    accessible_conversation_ids = Conversations::AgentAccessService.apply_scope(
      Current.account.conversations,
      Current.user,
      Current.account
    ).select(:id)

    relation.where(conversation_id: accessible_conversation_ids)
  end

  def restricted_agent?
    account_user = Current.account.account_users.find_by(user: Current.user)
    Conversations::AgentAccessService.restricted_agent?(account_user)
  end

  def permitted_user_ids
    return params[:user_ids] unless restricted_agent?

    [Current.user.id]
  end
end
