class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true if @account_user&.administrator?

    # Check if user has access to the conversation through inbox membership
    return true if user_assigned_inboxes.include?(record.inbox)

    # Check if user has access to the conversation through team membership
    user_assigned_teams.include?(record.team) if record.team.present?
  end

  def destroy?
    @account_user&.administrator?
  end

  private

  def user_assigned_inboxes
    @user.inboxes.where(account_id: @account.id)
  end

  def user_assigned_teams
    @user.teams.where(account_id: @account.id)
  end
end
