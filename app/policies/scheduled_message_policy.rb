class ScheduledMessagePolicy < ApplicationPolicy
  def index?
    accessible?
  end

  def create?
    accessible?
  end

  def update?
    accessible?
  end

  def destroy?
    accessible?
  end

  private

  def accessible?
    administrator? || agent_bot? || agent_can_view_conversation?
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

  def conversation
    record.respond_to?(:conversation) ? record.conversation : record
  end

  def inbox_access?
    user.inboxes.where(account_id: account&.id).exists?(id: conversation.inbox_id)
  end

  def team_access?
    return false if conversation.team_id.blank?

    user.teams.where(account_id: account&.id).exists?(id: conversation.team_id)
  end
end

ScheduledMessagePolicy.prepend_mod_with('ScheduledMessagePolicy')
