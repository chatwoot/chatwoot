class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    administrator? || agent_bot? || agent_can_view_conversation?
  end

  def destroy?
    administrator?
  end

  private

  def agent_can_view_conversation?
    inbox_access? || team_access? || participation_access?
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

  def participation_access?
    assigned_to_user? || participant?
  end

  def assigned_to_user?
    record.assignee_id == user.id
  end

  def participant?
    record.conversation_participants.exists?(user_id: user.id)
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
