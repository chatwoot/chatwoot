class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def destroy?
    administrator?
  end

  def show?
    return true if administrator? || agent_bot?
    return false unless agent_can_view_conversation?

    permitted_by_conversation_permissions?
  end

  private

  def agent_can_view_conversation?
    inbox_access? || team_access?
  end

  def administrator?
    account_user&.administrator?
  end

  def agent_bot?
    user.is_a?(AgentBot)
  end

  def inbox_access?
    user.inboxes.where(account_id: account&.id).exists?(id: record.inbox_id)
  end

  def team_access?
    return false if record.team_id.blank?

    user.teams.where(account_id: account&.id).exists?(id: record.team_id)
  end

  def assigned_to_user?
    record.assignee_id == user.id
  end

  def participant?
    record.conversation_participants.exists?(user_id: user.id)
  end

  def unassigned_conversation?
    record.assignee_id.nil?
  end

  def permissions
    @permissions ||= account_user&.permissions || []
  end

  # CommMate: enforce conversation visibility permissions on direct access as well
  def permitted_by_conversation_permissions?
    return true if permissions.include?('conversation_manage')
    return true if assigned_to_user?
    return true if can_view_unassigned?
    return true if can_view_participating?

    false
  end

  def can_view_unassigned?
    permissions.include?('conversation_unassigned_manage') && unassigned_conversation?
  end

  def can_view_participating?
    permissions.include?('conversation_participating_manage') && participant?
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
