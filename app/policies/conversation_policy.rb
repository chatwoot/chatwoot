class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def destroy?
    administrator?
  end

  def show?
    administrator? || agent_bot? || agent_can_view_conversation?
  end

  private

  def agent_can_view_conversation?
    # Check if agent has inbox or team access first
    has_basic_access = inbox_access? || team_access?
    return false unless has_basic_access

    # If agent has participating_only restriction, only allow if currently assigned
    return assigned_to_user? if account_user&.participating_only?

    # Default: if agent has inbox/team access, they can view
    true
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

  # Check if user has sent at least one message in this conversation
  def participated?
    record.messages.exists?(sender_id: user.id, sender_type: 'User')
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
