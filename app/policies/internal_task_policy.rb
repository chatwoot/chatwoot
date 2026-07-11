class InternalTaskPolicy < ApplicationPolicy
  def index?
    agent_or_admin?
  end

  def show?
    agent_or_admin? && accessible_task?
  end

  def create?
    agent_or_admin? && conversation_accessible?
  end

  def update?
    agent_or_admin? && can_modify_task?
  end

  def claim?
    update?
  end

  def start?
    update?
  end

  def complete?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.none unless account_user

      if account_user.administrator?
        scope.where(account_id: account.id)
      else
        team_ids = user.teams.where(account_id: account.id).pluck(:id)
        scope.where(account_id: account.id)
             .where('assigned_to_id = :user_id OR team_id IN (:team_ids) OR (assigned_to_id IS NULL AND team_id IS NULL)',
                    user_id: user.id, team_ids: team_ids.presence || [0])
      end
    end
  end

  private

  def agent_or_admin?
    account_user&.administrator? || account_user&.agent?
  end

  def accessible_task?
    return true if account_user.administrator?

    record.assigned_to_id == user.id ||
      user.teams.exists?(id: record.team_id) ||
      (record.assigned_to_id.nil? && record.team_id.nil?)
  end

  def conversation_accessible?
    return true if record.is_a?(Class)

    conversation = record.is_a?(Conversation) ? record : record.conversation
    ConversationPolicy.new(user_context, conversation).show?
  end

  def can_modify_task?
    return true if account_user.administrator?
    return true if record.created_by_id == user.id
    return true if record.assigned_to_id == user.id
    return true if record.assigned_to_id.nil? && record.team_id.present? && user.teams.exists?(id: record.team_id)

    false
  end
end
