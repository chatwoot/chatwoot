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

    agent_access_allowed?
  end

  def update?
    show?
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

  def agent_access_allowed?
    return true unless Conversations::AgentAccessService.restricted_agent?(account_user)

    Conversations::AgentAccessService.new(conversation: record, user: user, account: account, account_user: account_user).allowed?
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
