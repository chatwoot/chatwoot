class InternalConversationPolicy < ApplicationPolicy
  def index?
    agent_or_admin?
  end

  def show?
    agent_or_admin? && accessible_room?
  end

  def create_message?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.none unless account_user

      if account_user.administrator?
        scope.where(account_id: account.id)
      else
        team_ids = user.teams.where(account_id: account.id).pluck(:id)
        scope.where(account_id: account.id, team_id: team_ids.presence || [0])
      end
    end
  end

  private

  def agent_or_admin?
    account_user&.administrator? || account_user&.agent?
  end

  def accessible_room?
    return true if account_user.administrator?

    user.teams.exists?(id: record.team_id)
  end
end
