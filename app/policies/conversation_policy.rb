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

  # Narrower than `show?`, which lets any bot in the account read any conversation. A read
  # receipt is not a read: it puts the blue tick on the contact's phone, so it is limited to
  # the bot that actually serves the thread.
  def read_receipt?
    return agent_bot_serves_conversation? if agent_bot?

    show?
  end

  private

  # `user.inboxes` spans every association, disabled ones included, and a bot an operator
  # switched off must not go on putting blue ticks on the contact's phone. Active is what
  # `AgentBotListener#active_inbox_agent_bot` and `Conversation#set_active_bot_conversation`
  # both mean by a bot serving an inbox.
  def agent_bot_serves_conversation?
    return true if record.ai_assignee == user

    user.agent_bot_inboxes.active.exists?(inbox_id: record.inbox_id)
  end

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
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
